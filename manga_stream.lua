print 'Hello from Lua!!!! MangaStream woop woop'

mangaListType = 'All'
manga_list_url = 'http://mangastream.com/manga'
--<td><strong><a href="http://mangastream.com/manga/air_gear">Air Gear</a></strong></td>
manga_list_regex = '<td><strong><a href="(.-)">(.-)</a></strong></td>'
manga_list_next_page_regex = ''

--<td><a href="http://mangastream.com/r/air_gear/358/3139/1">358 - Trick 358</a></td>
chapter_list_regex = '<td><a href="(.-)">(.-)</a></td>'

--<li class="next"><a href="http://mangastream.com/r/toriko/389/3706/2">Next &rarr;</a></li>
next_page_regex = '<li class="next"><a href="(.-)">.-</a></li>'

-- http://mangastream.com/r/toriko/389/3706/2, we want the 3706 part
chapter_number_regex = '/r/.-/.-/(.-)/.-'

--<img id="manga-page" src="http://img.mangastream.com/cdn/manga/98/3704/005.png"/></a>
image_regex = '" src="(.-)"'
page_image_url_prefix = 'http:'

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


