/*  GitHub Repos, version 0.0.1
 *  (c) 2009 Jeff Rafter
 *
 *  Based on GitHub Badge by Dr Nic Williams (but with the good code removed)
 *
 *  You need: jquery.js
 *
 *  Notes: I am ignoring private repos, and the api doesn't give you gem or
 *  fork information that is present on the GitHub website. Pledgie info is
 *  also not available.
 *
 *--------------------------------------------------------------------------*/

var GitHubRepo = {
  Version: '0.0.1'
};

GitHubRepo = new function() {
  this.init = function(username, repository, callback) {
    this.username = username;
    this.repository = repository;
    var url = "http://github.com/api/v2/json/repos/show/" + username + "/" + repository + "?callback=GitHubRepo.load";
    this.request(url, callback)
  }
  
  this.load = function(data) {
    this.data = data.repository;
  }

  this.request = function(url, callback) {
    // inserting via DOM fails in Safari 2.0, so brute force approach
    if ("jQuery" in window) {
      jQuery.getScript(url,callback);
    } else {
      onLoadStr = (typeof callback == "undefined") ? "" : 'onload="' + callback + '()"';
      document.write('<script ' + onLoadStr + 'type="text/javascript" src="'+url+'"></script>');
    }
  }
  
  this.escapeContent = function(content) {
    return $('<div/>').text(content).html();      
  }
  
  this.content = function() {
    html = ""
    + "  <div class='title'>"
    + "    <div class='path'>"
    + "      <a href='http://github.com/" + this.username + "'>" + this.username + "</a> / <b><a href='http://github.com/" + this.username + "/" + this.repository + "/tree'>" + this.repository + "</a></b>"
    + "      <a href='http://github.com/" + this.username + "/" + this.repository + "/fork'><img src='http://assets0.github.com/images/modules/repos/fork_button.png' class='button' alt='fork'/></a>"
    + "      <a rel='http://github.com/" + this.username + "/" + this.repository + "' id='download_button' href='#'><img src='http://assets0.github.com/images/modules/repos/download_button.png' class='button' alt='download tarball'/></a>"
    + "      " + (this.links ? this.links : '')
    + "    </div>"
    + ""
    + "    <div style='' class='security public_security'>"
    + "      <a rel='facebox' href='#public_repo'><img alt='public' src='http://github.com/images/icons/public.png'/></a>"
    + "    </div>"
    + ""
    + "    <div class='hidden' id='public_repo'>"
    + "      This repository is public. Anyone may fork, clone, or view it."
    + "      <br/>"
    + "      <br/>"
    + "      Every repository with this icon (<img alt='public' src='http://github.com/images/icons/public.png'/>) is public."
    + "    </div>"
    + ""
    + "    <div class='flexipill'>"
    + "      <a href='http://github.com/" + this.username + "/" + this.repository + "/network'>"
    + "        <table cellspacing='0' cellpadding='0'><tbody><tr><td><img src='http://assets0.github.com/images/modules/repos/pills/forks.png' alt='Forks'/></td><td class='middle'><span>" + this.data.forks + "</span></td><td><img src='http://assets0.github.com/images/modules/repos/pills/right.png' alt='Right'/></td></tr></tbody></table>"
    + "      </a>"
    + "    </div>"
    + ""
    + "    <div class='flexipill'>"
    + "      <a href='http://github.com/" + this.username + "/" + this.repository + "/watchers'>"
    + "        <table cellspacing='0' cellpadding='0'><tbody><tr><td><img src='http://assets0.github.com/images/modules/repos/pills/watchers.png' alt='Watchers'/></td><td class='middle'><span>" + this.data.watchers + "</span></td><td><img src='http://assets0.github.com/images/modules/repos/pills/right.png' alt='Right'/></td></tr></tbody></table>"
    + "      </a>"
    + "    </div>"
    + "  </div>"
    + ""      
    + "  <div class='meta'>"
    + "    <table>"
    + "      <tbody>";
    
    // if (this.data.fork)
    // html += ""
    // + "        <tr>"
    // + "          <td class='label'>Fork:</td>"
    // + "          <td>Yes</td>"
    // + "        </tr>";
    
    if (this.data.description)
    html += ""
    + "        <tr>"
    + "          <td class='label'>Description:</td>"
    + "          <td>" + this.escapeContent(this.data.description) + "</td>"
    + "        </tr>";
      
    if (this.data.homepage)
    html += ""
    + "        <tr>"
    + "          <td class='label'>Homepage:</td>"
    + "          <td><a href='" + this.escapeContent(this.data.homepage) + "'>" + this.escapeContent(this.data.homepage) + "</a></td>"
    + "        </tr>";
    
    html += ""
    + "        <tr>"
    + "          <td class='label'>Public Clone URL:</td>"
    + "          <td>"
    + "            <a rel='#git-clone' class='git_url_facebox' href='git://github.com/" + this.username + "/" + this.repository + ".git'>git://github.com/" + this.username + "/" + this.repository + ".git</a>"
    + "            <object width='110' height='14' id='clippy' class='clippy' classid='clsid:d27cdb6e-ae6d-11cf-96b8-444553540000'>"
    + "            <param value='http://github.com/flash/clippy.swf' name='movie'/>"
    + "            <param value='always' name='allowScriptAccess'/>"
    + "            <param value='high' name='quality'/>"
    + "            <param value='noscale' name='scale'/>"
    + "            <param value='text=git://github.com/" + this.username + "/" + this.repository + ".git' name='FlashVars'/>"
    + "            <param value='#F0F0F0' name='bgcolor'/>"
    + "            <param value='opaque' name='wmode'/>"
    + "            <embed width='110' height='14' wmode='opaque' bgcolor='#F0F0F0' flashvars='text=git://github.com/" + this.username + "/" + this.repository + ".git' pluginspage='http://www.macromedia.com/go/getflashplayer' type='application/x-shockwave-flash' allowscriptaccess='always' quality='high' name='clippy' src='http://github.com/flash/clippy.swf'/>"
    + "            </object>"
    + "            <div style='display: none;' id='git-clone'>"
    + "              Give this clone URL to anyone."
    + "              <br/>"
    + "              <code>git clone git://github.com/" + this.username + "/" + this.repository + ".git </code>"
    + "            </div>"
    + "          </td>"
    + "        </tr>"
    + "      </tbody>"
    + "    </table>"   
    + "  </div>";

    return html;
  }  
};