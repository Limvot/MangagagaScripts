pageNo = 1

function getMangaListTypes()
    titleList = { }
    titleList[0] = 'All'
    titleList[1] = 'Most Popular'
    titleList[2] = 'Latest Update'
    titleList[3] = 'Newest'
    titleList['numTypes'] = 4
    allChar = '#ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    i = 1
    while i < (string.len(allChar) + 1) do
        titleList[titleList['numTypes'] + i - 1] = string.sub(allChar, i, i)
        i = i + 1
    end
    titleList['numTypes'] = titleList['numTypes'] + i
    return titleList
end

function getMangaListPage(mangaListType)
    print('type is ' .. mangaListType)
    if mangaListType == 'All' then
        return getMangaList('http://kissmanga.com/MangaList?page=' .. pageNo)
    elseif mangaListType == 'Most Popular' then
        return getMangaList('http://kissmanga.com/MangaList/MostPopular?page=' .. pageNo)
    elseif mangaListType == 'Latest Update' then
        return getMangaList('http://kissmanga.com/MangaList/LatestUpdate?page=' .. pageNo)
    elseif mangaListType == 'Newest' then
        return getMangaList('http://kissmanga.com/MangaList/Newest?page=' .. pageNo)
    elseif mangaListType == '#' then
        return getMangaList('http://kissmanga.com/MangaList?c=0&page=' .. pageNo)
    end

    return getMangaList('http://kissmanga.com/MangaList?c=' .. mangaListType .. '&page=' .. pageNo)
end

function getMangaList(url)
   print('About to getMangaList!')
   print(apiObj)
   path = download_cf(url)
   pageSource = apiObj:readFile(path)
   apiObj:note('LuaScript downloaded (for manga): ' .. path)
   daList = {}
   regex = '</div>\'>.-<a href="/Manga/(.-)">(.-)</a>'
   apiObj:note('Manga List Regex: ' .. regex)
   beginning, ending, mangaURL, mangaTitle = string.find(pageSource, regex)
   index = 0
   while ending do
       daList[index] = {title = mangaTitle, url = mangaURL}
       beginning, ending, mangaURL, mangaTitle = string.find(pageSource, regex, ending+1)
       index = index + 1
   end
   daList['numManga'] = index
   return daList
end


function initManga(manga)
   mangaURL = 'http://kissmanga.com/Manga' .. '/' .. manga['url'] .. '?confirm=yes'
   apiObj:note('Manga Path: ' .. mangaURL)
   path = download_cf(mangaURL)
   pageSource = apiObj:readFile(path)
   apiObj:note('LuaScript downloaded (for chapter): ' .. path)

   -- Set up manga description and other nicities
   descriptionRegex = '<span class="info">Summary:</span>.-<p.->(.-)</p>'
   _, _, mangaDescription = string.find(pageSource, descriptionRegex)
   manga['description'] = mangaDescription

   daList = {}
   --regex = '<a +href="/Manga/' .. escapeRegexStr(manga['url']) .. '/(.-)?id.-".->(.-)</a>'
   regex = '<a +href="/Manga/' .. escapeRegexStr(manga['url']) .. '/(.-)".->(.-)</a>'
   apiObj:note('Chapter List Regex: ' .. regex)
   beginning, ending, chapterURL, chapterTitle = string.find(pageSource, regex)
   index = 0
   while ending do
       daList[index] = {title = chapterTitle, url = chapterURL, chapterSetUp = false}
       beginning, ending, chapterURL, chapterTitle = string.find(pageSource, regex, ending+1)
       index = index + 1
   end
   daList['numChapters'] = index
   manga['chapter_list'] = daList
end

function getMangaChapterList(manga)
    return manga['chapter_list']
end


function getMangaChapterNumPages(manga, chapter)
   if not chapter['chapterSetUp'] then
       setUpChapter(manga, chapter)
   end
   return chapter['pageList']['numPages']
end


function getMangaChapterPage(manga, chapter, page)
   if not chapter['chapterSetUp'] then
       setUpChapter(manga, chapter)
   end
   apiObj:note('lookie')
   apiObj:note('there are # pages')
   apiObj:note(chapter['pageList']['numPages'])
   apiObj:note(chapter['pageList'])
   apiObj:note(chapter['pageList'][page])
   apiObj:note(chapter['pageList'][page]['url'])
   return download_cf(chapter['pageList'][page]['url'])
end


function setUpChapter(manga, chapter)

       pageURL = 'http://kissmanga.com/Manga' .. '/' .. manga['url'] .. '/' .. chapter['url']

       apiObj:note('The Page URL is: ' .. pageURL)
       path = download_cf(pageURL)
       apiObj:note('After download')
       pageSource = apiObj:readFile(path)


       --let's get with it
       --this won't stop us
       --they encode their links now, so we download all their crypto js
       --and execute it (over and over for every link right now...)
       path = download_cf('http://kissmanga.com/Scripts/ca.js')
       ca_js = apiObj:readFile(path)
       path = download_cf('http://kissmanga.com/Scripts/lo.js')
       lo_js = apiObj:readFile(path)
       pageJS = ca_js .. ';' .. lo_js

--var _0xa5a2 = ["\x37\x32\x6E\x6E\x61\x73\x64\x61\x73\x64\x39\x61\x73\x    64\x6E\x31\x32\x33"]; chko = _0xa5a2[0]; key = CryptoJS.SHA256(chko)
--var _0x2c7e = ["\x6E\x61\x73\x64\x62\x61\x73\x64\x36\x31\x32\x62\x61\x    73\x64"]; chko = chko + _0x2c7e[0]; key = CryptoJS.SHA256(chko)

       keyjs_regex = '(var _[%a%d]- = %["[^"]-"%]; -chko = %a- -+? -_[%a%d]-%[0%]; -key = CryptoJS.SHA256%(chko%))'
       beginning, ending, keyjs = string.find(pageSource, keyjs_regex)
       while ending do
           pageJS = pageJS .. ';' .. keyjs
           beginning, ending, keyjs = string.find(pageSource, keyjs_regex, ending+1)
       end
       pageJS = pageJS .. ';var message = "no message"; function alert(a) { message = a };'


       regex = 'lstImages%.push%((.-)%);'
       apiObj:note('Page List Regex: ' .. regex)
       beginning, ending, pageURL = string.find(pageSource, regex)
       index = 0
       daList = {}
       while ending do
           daList[index] = {url = apiObj:doDaJS(pageJS .. pageURL)}
           apiObj:note("orig url is")
           apiObj:note(pageURL)
           apiObj:note("decoded url is")
           apiObj:note(daList[index]['url'])
           beginning, ending, pageURL = string.find(pageSource, regex, ending+1)
           index = index + 1
       end
       daList['numPages'] = index
       chapter['pageList'] = daList
       chapter['chapterSetUp'] = true
end

s_manga_list = {}
s_chapter_list = {}
s_manga = {}
s_chapter = {}

function handleRequest(req)
    print("Lua, handling request!")
    r_filter = req:getFilter()
    r_manga = req:getManga()
    r_chapter = req:getChapter()
    r_page = req:getPage()
    ret = {}

    if r_manga == "" then
        -- This is a request for manga listing
       mangaList = getMangaListPage(r_filter)
       print("Request got manga list")
       index = 0
       for k,v in ipairs(mangaList) do
           manga_title = v['title']
           manga_url = v['url']
           s_manga_list[manga_title] = manga_url
           ret[index] = manga_title
           index = index + 1
       end
       return ret
    end

    if r_chapter == "" then
        -- This is a request for chapter listing
        print("Got a request for a chapter listing")
        s_manga = { }
        s_manga['url'] = s_manga_list[r_manga]
        initManga(s_manga)
        chap_list = s_manga['chapter_list']
        ret[0] = s_manga['description']
        index = 1
        for k,v in pairs(chap_list) do
            if k ~= 'numChapters' then
                ch_title = v['title']
                ch_url = v['url']
                ret[index] = ch_title
                s_chapter_list[ch_title] = ch_url
                index = index + 1
            end
        end
        return ret
    end

    if r_page == "" then
        -- Requesting the number of pages for the chapter
        s_chapter = {}
        s_chapter['url'] = s_chapter_list[r_chapter]
        s_chapter['chapterSetUp'] = false
        tmp = getMangaChapterNumPages(s_manga,s_chapter)
        print("Page Number Request")
        print(tmp)
        ret[0] = tostring(tmp)
        ret[1] = tostring(tmp)
        ret['numPages'] = tostring(tmp)
        return ret
    end

    -- We have a page request
    print("Requesting page")
    print(r_page)
    s_chapter['url'] = s_chapter_list[r_chapter]
    page_url = getMangaChapterPage(s_manga, s_chapter, tonumber(r_page))
    print("page url is...")
    print(page_url)
    ret[0] = page_url
    ret[1] = page_url
    return ret
end
