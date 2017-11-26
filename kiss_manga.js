function getMangaListTypes() {
    return ["All", "Most Popular", "Latest Update", "Newest"]
}


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
            results.push(match[2])
        }
        return results
    } else if (r_chapter == "") {
        api.note("request for chapter list")
    } else if (r_page == "")    {
        api.note("request for num pages")
    } else {
        api.note("request for page")
    }
}
