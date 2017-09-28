print "Hello from Lua!!!! Jamini's Box woop woop"

mangaListType = 'All'
manga_list_url = 'https://jaiminisbox.com/reader/directory'

--<div class="title"><a href="https://jaiminisbox.com/reader/series/bakuman/" title="Bakuman">Bakuman</a> <span class="meta"></span></div>
manga_list_regex = '<div class="title"><a href="(.-)" title=".-">(.-)</a>'

--<a class="gbutton fright" href="https://jaiminisbox.com/reader/directory/2/">Next »</a>
manga_list_next_page_regex = '>Last »»</a>.-<a class="gbutton fright" href="(.-)">Next »</a>'
--<div class="title"><a href="https://jaiminisbox.com/reader/read/black_clover/en/0/123/" title="Page 123: The commoner's trap">Page 123: The commoner's trap</a></div>
chapter_list_regex = '<div class="title"><a href="(.-)" title=".-">(.-)</a></div>'

--<a href="https://jaiminisbox.com/reader/read/black_clover/en/0/112/page/2" onClick="return nextPage();">
next_page_regex = '<a href="([^"]-)" onClick="return nextPage%(%);">'

-- http://mangastream.com/r/toriko/389/3706/2, we want the 3706 part
chapter_number_regex = 'jaiminisbox.com/reader/read/.-/.-/.-/(.-)/'

--<img class="open" src="https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&refresh=604800&url=https://jaiminisbox.com/reader/content/comics/black_clover_55f3d2ec5caf2/112-0-royal-knights-selection-exam_592ff6a8f3d1b/m0001.jpg"/>
--image_regex = '<img class="open" src=".-&url=(.-)"/>'
image_regex = '<img class="open" src="(.-)"'
page_image_url_prefix = ''

function getMangaListTypes()
    titleList = { }
    titleList[0] = 'All'
    titleList['numTypes'] = 1
    return titleList
end

function getMangaListPage(type)
   return meta_getMangaListPage(manga_list_url, manga_list_regex, manga_list_next_page_regex)
end

function initManga(manga)
   meta_initManga(manga, chapter_list_regex)
end

function getMangaChapterList(manga)
    return meta_getMangaChapterList(manga)
end

function getMangaChapterNumPages(manga, chapter)
   return meta_getMangaChapterNumPages(manga, chapter, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
end

function getMangaChapterPage(manga, chapter, page)
   return meta_getMangaChapterPage(manga, chapter, page, chapter_number_regex, image_regex, page_image_url_prefix, next_page_regex)
end
