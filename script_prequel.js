function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}

// polyfill for String.includes
if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    'use strict';
    if (typeof start !== 'number') {
      start = 0;
    }

    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}

function downloadCF(url) {
    var result = api.downloadWithRequestHeadersAndReferrer(url, '')
    var file_name = result.getFirst()
    var response_headers = result.getSecond()

    if (response_headers.containsKey(null)) {
        if (response_headers.get(null).get(0).includes('503') &&
            response_headers.containsKey('Server') &&
            response_headers.get('Server').get(0).includes('cloudflare')) {

            api.note("CLLOUDFLARE DETECTED!")
            var page = api.readFile(file_name)

            var challenge      = page.match('name="jschl_vc" value="(.*?)"')[1]
            var challenge_pass = page.match('name="pass" value="(.*?)"')[1]
            var to_eval        = page.match(/setTimeout\(function\(\){([\s\S]*?)}, 4000\);/)[1]

            to_eval = to_eval.replace(/\s*?t =.*?;/g, '')
            to_eval = to_eval.replace(/\s*?a =.*?;/g, '')
            to_eval = to_eval.replace(/\s*?f =.*?;/g, '')
            to_eval = to_eval.replace(/\s*?r =.*?;/g, '')
            to_eval = to_eval.replace(/\s*?t\.innerHTML.*?;/g, '')
            to_eval = to_eval.replace(/\s*?f\.submit.*?;/g, '')
            to_eval = to_eval.replace(/\s*?a\.value = ([\s\S]*?) \+ t.length;([\s\S]*)/g, '$1')

            var domain = url.match('http://(.*?)/')[1]
            api.note("Trying to eval " + to_eval)
            var evaled = eval(to_eval)
            api.note('evaled is ' + evaled)
            var answer = evaled + domain.length
            api.note('full answer is ' + answer)
            var protocol = url.match('(.*?)://')[1]
            var submit = protocol + '://' + domain + '/cdn-cgi/l/chk_jschl' +
                '?jschl_vc=' + challenge + '&jschl_answer=' + answer + '&pass=' + challenge_pass
            api.note('waiting...')
            api.sleep(4000)
            api.note('done')
            return api.downloadWithRequestHeadersAndReferrer(submit,url).getFirst()
        } else {
            api.note("No cloudflare - no string")
        }
    } else {
        api.note("not cloudflare - no refresh")
    }

    return file_name
}
