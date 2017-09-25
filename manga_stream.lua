print 'Hello from Lua!!!! MangaStream woop woop'

mangaListType = 'All'

--<td><strong><a href="http://mangastream.com/manga/air_gear">Air Gear</a></strong></td>
manga_list_regex = '<td><strong><a href="(.-)">(.-)</a></strong></td>'

--<td><a href="http://mangastream.com/r/air_gear/358/3139/1">358 - Trick 358</a></td>
chapter_list_regex = '<td><a href="(.-)">(.-)</a></td>'

--<li class="next"><a href="http://mangastream.com/r/toriko/389/3706/2">Next &rarr;</a></li>
next_page_regex = '<li class="next"><a href="(.-)">.-</a></li>'

-- http://mangastream.com/r/toriko/389/3706/2, we want the 3706 part
chapter_number_regex = 'mangastream.com/r/.-/.-/(.-)/.-'

--<img id="manga-page" src="http://img.mangastream.com/cdn/manga/98/3704/005.png"/></a>
image_regex = '" src="(.-)"'

function getMangaListTypes()
    titleList = { }
    titleList[0] = 'All'
    titleList['numTypes'] = 1
    return titleList
end

function getMangaListPage(type)
   url = 'http://mangastream.com/manga'
   print('About to getMangaList!')
   path = download_cf(url)
   pageSource = apiObj:readFile(path)
   apiObj:note('LuaScript downloaded (for manga): ' .. path)
   daList = {}
   beginning, ending, mangaURL, mangaTitle = string.find(pageSource, manga_list_regex)
   index = 0
   while ending do
       daList[index] = {title = mangaTitle, url = mangaURL}
       beginning, ending, mangaURL, mangaTitle = string.find(pageSource, manga_list_regex, ending+1)
       index = index + 1
   end
   daList['numManga'] = index
   return daList
end

function initManga(manga)
   apiObj:note('Manga Path: ' .. manga['url'])
   path = download_cf(manga['url'])

   pageSource = apiObj:readFile(path)

   -- Set up manga description and other nicities
   -- IF WE HAD ONE
   manga['description'] = 'MangaStream does not provide descriptions'

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
   return download_cf(chapter['pageList'][page]['url'])
end

function setUpChapter(manga, chapter)
       -- manga stream's chapter page is the first page of the chapter
       pageURL = chapter['url']
       apiObj:note('The chapter first page URL is: ' .. pageURL)
       _, _, thisChapterNum = string.find(pageURL, chapter_number_regex)
       nextPageChapterNum = thisChapterNum

       index = 0
       daList = {}
       ending = 0
       while ending and nextPageChapterNum == thisChapterNum do
           apiObj:note('pageURL: ' .. pageURL)
           pagePath = download_cf(pageURL)
           pageSource = apiObj:readFile(pagePath)
           -- get the image url
           _, _, pageImageURL = string.find(pageSource, image_regex)
           pageImageURL = 'https:' .. pageImageURL
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
end

