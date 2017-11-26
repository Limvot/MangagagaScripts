function getMangaListTypes() {
    return ["All", "Most Popular", "Latest Update", "Newest"]
}

var manga = {}

function handleRequest(req) {
    api.note("JS, handling request!")
    var r_filter  = req.getFilter()
    var r_manga   = req.getManga()
    var r_chapter = req.getChapter()
    var r_page    = req.getPage()

    var pageNo = 1

    if        (r_manga == "")   {
        api.note("request for manga list")
        var url = 'http://kissmanga.com/MangaList?page=' + pageNo
        if        (r_filter == "All") {
            // default yo
        } else if (r_filter == "Most Popular") {
            url = 'http://kissmanga.com/MangaList/MostPopular?page=' + pageNo
        } else if (r_filter =="Latest Update") {
            url = 'http://kissmanga.com/MangaList/LatestUpdate?page=' + pageNo
        } else if (r_filter =="Newest") {
            url = 'http://kissmanga.com/MangaList/Newest?page=' + pageNo
        }
        var path = downloadCF(url)
        var pageSource = api.readFile(path)

        var regex = /<\/div>'>[\s\S]*?<a href="\/Manga\/([\s\S]*?)">([\s\S]*?)<\/a>/g
        var match
        var results = []
        while (match = regex.exec(pageSource)) {
            manga[match[2]] = {title: match[2], url: match[1]}
            results.push(match[2])
        }
        return results
    } else if (r_chapter == "") {
        api.note("request for chapter list")
        var mangaURL = 'http://kissmanga.com/Manga' + '/' + manga[r_manga]['url'] + '?confirm=yes'
        var path = downloadCF(mangaURL)
        var pageSource = api.readFile(path)
        var descriptionRegex = /<span class="info">Summary:<\/span>[\s\S]*?<p[\s\S]*?>([\s\S]*?)<\/p>/g
        manga[r_manga]['description'] = descriptionRegex.exec(pageSource)[1]

        var chapterRegex = new RegExp('<a +href="/Manga/' + escapeRegExp(manga[r_manga]['url']) + '/([\\s\\S]*?)"[\\s\\S]*?>([\\s\\S]*?)</a>', 'g')
        var match
        var results = []
        manga[r_manga]['chapters'] = {}
        while (match = chapterRegex.exec(pageSource)) {
            var chapter = {title: match[2], url: match[1]}
            manga[r_manga]['chapters'][chapter.title] = chapter
            results.push(chapter.title)
        }
        return results
    } else if (r_page == "")    {
        api.note("request for num pages")

        var pagesURL = 'http://kissmanga.com/Manga/' + manga[r_manga]['url'] + '/' + manga[r_manga]['chapters'][r_chapter]['url']

        api.note('The Pages URL is: ' + pagesURL)
        var path = downloadCF(pagesURL)
        api.note('After download')
        var pageSource = api.readFile(path)

        //let's get with it
        //this won't stop us
        //they encode their links now, so we download all their crypto js
        //and execute it (over and over for every link right now...)
        path = downloadCF('http://kissmanga.com/Scripts/ca.js')
        var ca_js = api.readFile(path)
        path = downloadCF('http://kissmanga.com/Scripts/lo.js')
        var lo_js = api.readFile(path)
        var pageJS = ca_js + ';' + lo_js

        //var _0xa5a2 = ["\x37\x32\x6E\x6E\x61\x73\x64\x61\x73\x64\x39\x61\x73\x    64\x6E\x31\x32\x33"]; chko = _0xa5a2[0]; key = CryptoJS.SHA256(chko)
        //var _0x2c7e = ["\x6E\x61\x73\x64\x62\x61\x73\x64\x36\x31\x32\x62\x61\x    73\x64"]; chko = chko + _0x2c7e[0]; key = CryptoJS.SHA256(chko)

        var varkeyjs_regex = /(var _\w*? = \["[^"]*?"\]; *?chko = \w*? *?\+? *?_\w*?\[0\]; *?key = CryptoJS.SHA256\(chko\))/g
        var match
        var results = []
        while (match = varkeyjs_regex.exec(pageSource)) {
            api.note("Found key stuff " + match[1])
            pageJS += ";" + match[1]
        }
        pageJS += ';var message = "no message"; function alert(a) { message = a };'

        var regex = /lstImages\.push\((.*?)\);/g
        var match
        var results = []
        var numPages = 0
        manga[r_manga]['chapters'][r_chapter]['pages'] = []
        while (match = regex.exec(pageSource)) {
            var pageURL = match[1]
            api.note("evaling pageJS and " + pageURL)
            var url = eval(pageJS + pageURL)
            manga[r_manga]['chapters'][r_chapter]['pages'].push(url)
        }
        api.note("Pages found")
        api.note(manga[r_manga]['chapters'][r_chapter]['pages'])

        return [ manga[r_manga]['chapters'][r_chapter]['pages'].length.toString() ]
    } else {
        api.note("request for page")
        return [ downloadCF(manga[r_manga]['chapters'][r_chapter]['pages'][r_page]) ]
    }
}
