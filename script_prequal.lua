print('Lua prequal!')

apiObj = 0
function init(apiObjIn)
   apiObj = apiObjIn
end

function escapeRegexStr(theStr)
   newStr = (theStr:gsub('[%-%.%+%[%]%(%)%$$^%%%?%*]', '%%%1'):gsub('%z','%%z'))
   return newStr
end

function download_cf(str)
    print('Downloading with CloudFlare passthrough ' .. str)
    result = apiObj:downloadWithRequestHeadersAndReferrer(str,'')
    print('result')
    file_name = result:getFirst()
    response_headers = result:getSecond()
    if response_headers:containsKey(nil) then
        if string.find(response_headers:get(nil):get(0), escapeRegexStr('503'))
            and response_headers:containsKey('Server')
            and string.find(response_headers:get('Server'):get(0), escapeRegexStr('cloudflare-nginx')) then
            print('CLOUDFLARE DETECTED')
            page = apiObj:readFile(file_name)
            print(page)
            _,_,challenge = string.find(page, 'name="jschl_vc" value="(.-)"')
            print('found challenge: ')
            print(challenge)
            _,_,challenge_pass = string.find(page, 'name="pass" value="(.-)"')
            print('found challenge_pass: ')
            print(challenge_pass)
            _,_,to_eval = string.find(page, escapeRegexStr('setTimeout(function(){') .. '(.-)' .. escapeRegexStr('}, 4000);'))
            print('found to_eval: ')
            print(to_eval)
            to_eval = string.gsub(to_eval, '%s-t =.-;', '')
            to_eval = string.gsub(to_eval, '%s-a =.-;', '')
            to_eval = string.gsub(to_eval, '%s-f =.-;', '')
            to_eval = string.gsub(to_eval, '%s-r =.-;', '')
            to_eval = string.gsub(to_eval, '%s-t%.innerHTML.-;', '')
            to_eval = string.gsub(to_eval, '%s-f%.submit.-;', '')
            to_eval = string.gsub(to_eval, '%s-a%.value = (.-) %+ t.length;(.*)', '%1')
            print('edited to')
            print(to_eval)
            _,_,domain = string.find(str, 'http://(.-)/')
            print('domain is')
            print(domain)
            print('value is')
            answer = tonumber(apiObj:doDaJS(to_eval)) + string.len(domain)
            print(answer)
            _,_,protocol = string.find(str, '(.-)://')
            print('protocol')
            print(protocol)
            submit = protocol .. '://' .. domain .. '/cdn-cgi/l/chk_jschl'
                ..'?jschl_vc='..challenge..'&jschl_answer='..answer..'&pass='..challenge_pass
            print('submit')
            print(submit)
            print('waiting...')
            apiObj:sleep(5000)
            print('done')
            return apiObj:downloadWithRequestHeadersAndReferrer(submit,str):getFirst()
        else
            print('NO CLOUDFLARE - no string ')
            print(find_string)
            print(escapeRegexStr('URL=/cdn-cgi/'))
            print(find_result)
        end
    else
        print('NO CLOUDFLARE - no refresh')
    end

    return file_name
end

--
-- Begin basic meta functions
--

function meta_getMangaListPage(manga_list_URL, manga_list_regex, manga_list_next_page_regex)
   print('About to getMangaList!')
   current_page_url = manga_list_url
   daList = {}
   index = 0
   repeat
       apiObj:note('DOWNLOADING MANGA LIST PAGE')
       path = download_cf(current_page_url)
       pageSource = apiObj:readFile(path)
       ending = -1
       repeat
           beginning, ending, mangaURL, mangaTitle = string.find(pageSource, manga_list_regex, ending+1)
           daList[index] = {title = mangaTitle, url = mangaURL}
           index = index + 1
       until not ending
       -- take off final nil entry
       index = index - 1
       -- get the next page if it exists
       _, _, current_page_url = string.find(pageSource, manga_list_next_page_regex)
   until not current_page_url
   daList['numManga'] = index
   return daList
end

function meta_initManga(manga, chapter_list_regex)
   apiObj:note('Manga Path: ' .. manga['url'])
   apiObj:note('DOWNLOADING MANGA CHAPTER LIST PAGE')
   path = download_cf(manga['url'])
   pageSource = apiObj:readFile(path)

   -- Set up manga description and other nicities
   -- IF WE HAD ONE
   manga['description'] = 'META does not provide descriptions'

   apiObj:note('Chapter List Regex: ' .. chapter_list_regex)
   daList = {}
   beginning, ending, chapterURL, chapterTitle = string.find(pageSource, chapter_list_regex)
   index = 0
   while ending do
       daList[index] = {title = chapterTitle, url = chapterURL, chapterSetUp = false}
       beginning, ending, chapterURL, chapterTitle = string.find(pageSource, chapter_list_regex, ending+1)
       index = index + 1
   end
   daList['numChapters'] = index
   manga['chapter_list'] = daList
end

function meta_getMangaChapterList(manga)
    return manga['chapter_list']
end

function meta_getMangaChapterNumPages(manga, chapter, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
   if not chapter['chapterSetUp'] then
       meta_setUpChapter(manga, chapter, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
   end
   return chapter['pageList']['numPages']
end

function meta_getMangaChapterPage(manga, chapter, page, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
   if not chapter['chapterSetUp'] then
       meta_setUpChapter(manga, chapter, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
   end
   apiObj:note('DOWNLOADING MANGA REAL PAGE')
   return download_cf(chapter['pageList'][page]['url'])
end

function meta_setUpChapter(manga, chapter, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
       -- manga stream's chapter page is the first page of the chapter
       pageURL = chapter['url']
       apiObj:note('The chapter first page URL is: ' .. pageURL)
       _, _, thisChapterNum = string.find(pageURL, chapter_number_regex)
       nextPageChapterNum = thisChapterNum
       apiObj:note('The chapters number is : ' .. thisChapterNum)

       index = 0
       daList = {}
       ending = 0
       while ending and nextPageChapterNum == thisChapterNum do
           apiObj:note('DOWNLOADING MANGA CONTAINER PAGE')
           apiObj:note('pageURL: ' .. pageURL)
           apiObj:status('downloading page continer ' .. index)
           pagePath = download_cf(pageURL)
           pageSource = apiObj:readFile(pagePath)
           -- get the image url
           _, _, pageImageURL = string.find(pageSource, image_regex)
           -- happens on final page of most recent chapter, as 1 beyond end page redirects to main listing
           if not pageImageURL then
               break
           end
           if page_image_url_prefix ~= '' then
               pageImageURL = page_image_url_prefix .. pageImageURL
           end
           apiObj:note('pageImageURL: ' .. pageImageURL)

           daList[index] = {url = pageImageURL}
           -- get the next page url
           _, ending, pageURL = string.find(pageSource, next_page_regex, 0)
           -- get the chapter number out of this next page regex so we know when to stop
           if ending then
               _, _, thisChapterNum = string.find(pageURL, chapter_number_regex)
           end 
           index = index + 1
       end
       daList['numPages'] = index
       chapter['pageList'] = daList
       chapter['chapterSetUp'] = true
       apiObj:note('set up chapter with ' .. index .. ' pages!')
       apiObj:status('set up chapter with ' .. index .. ' pages')
end


