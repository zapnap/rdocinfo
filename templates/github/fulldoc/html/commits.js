/*  GitHub Commits, version 0.0.1
 *  (c) 2009 Jeff Rafter
 *
 *  Based on GitHub Badge by Dr Nic Williams (but with the good code removed)
 *
 *  You need: jquery.js, md5.js
 *
 *  See http://pajhome.org.uk/crypt/md5 for more info.
 *
 *--------------------------------------------------------------------------*/

var GitHubCommit = {
  Version: '0.0.1'
};

GitHubCommit = new function() {
  this.init = function(username, repository, commit, callback) {
    this.username = username;
    this.repository = repository;
    this.commit = commit;
    var url = "http://github.com/api/v2/json/commits/show/" + username + "/" + repository + "/" + commit + "?callback=GitHubCommit.load";
    this.request(url, callback)
  }
  
  this.load = function(data) {
    this.commit = data.commit;
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
  
  this.escapeDate = function(date) {
    var d = new Date();
    var regexp = /(\d\d\d\d)(-)?(\d\d)(-)?(\d\d)(T)?(\d\d)(:)?(\d\d)(:)?(\d\d)(\.\d+)?(Z|([+-])(\d\d)(:)?(\d\d))/;  
    if (date.toString().match(new RegExp(regexp))) {
      var m = date.match(new RegExp(regexp));
      var offset = 0;    
      d.setUTCDate(1);
      d.setUTCFullYear(parseInt(m[1],10));
      d.setUTCMonth(parseInt(m[3],10) - 1);
      d.setUTCDate(parseInt(m[5],10));
      d.setUTCHours(parseInt(m[7],10));
      d.setUTCMinutes(parseInt(m[9],10));
      d.setUTCSeconds(parseInt(m[11],10));
      if (m[12])
        d.setUTCMilliseconds(parseFloat(m[12]) * 1000);
      else
        d.setUTCMilliseconds(0);
      if (m[13] != 'Z') {
        offset = (m[15] * 60) + parseInt(m[17],10);
        offset *= ((m[14] == '-') ? -1 : 1);
        d.setTime(d.getTime() - offset * 60 * 1000);
      }
    } else {
      d.setTime(Date.parse(date));
    }
    var months = Array("January","February","March","April","May","June","July","August","September","October","November","December");
    return months[d.getMonth()] + ' ' + d.getDay() + ', ' + d.getFullYear();
  }
  
  this.escapeContent = function(content) {
    return $('<div/>').text(content).html();      
  }
  
  this.content = function() {
    html = "" +
    "<div class='group'>" + 
    "  <div class='envelope commit'>" + 
    "    <div class='human'>" + 
    "      <div class='message'><pre><a href='" + this.commit.url + "'>" + this.escapeContent(this.commit.message) + "</a></pre></div>" + 
    "      <div class='actor'>" + 
    "        <div class='gravatar'>" +               
    "          <img width='30' height='30' src='http://www.gravatar.com/avatar/" + hex_md5(this.commit.author.email) + "?s=30&amp;d=http%3A%2F%2Fgithub.com%2Fimages%2Fgravatars%2Fgravatar-30.png' alt=''/>" + 
    "        </div>" + 
    "        <div class='name'>" + this.escapeContent(this.commit.author.name) + " <span>(author)</span></div>" + 
    "        <div class='date'><abbr title='" + this.commit.authored_date + "' class='relatize'>" + this.escapeDate(this.commit.authored_date) + "</abbr></div>" + 
    "      </div>"; 
    
    if (this.commit.committer)
      html += 
      "      <div class='actor'>" + 
      "        <div class='gravatar'>" +                                             
      "          <img width='30' height='30' src='http://www.gravatar.com/avatar/" + hex_md5(this.commit.committer.email) + "?s=30&amp;d=http%3A%2F%2Fgithub.com%2Fimages%2Fgravatars%2Fgravatar-30.png' alt=''/>" + 
      "        </div>" + 
      "        <div class='name'>" + this.escapeContent(this.commit.committer.name) + " <span>(committer)</span></div>" + 
      "        <div class='date'><abbr title='" + this.commit.committed_date + "' class='relatize'>" + this.escapeDate(this.commit.committed_date) + "</abbr></div>" + 
      "      </div>";
    
    html += 
    "    </div>" +         
    "    <div class='machine'>" + 
    "      <span>c</span>ommit <a hotkey='c' href='" + this.commit.url + "'>" + this.commit.id + "</a><br/>" + 
    "      <span>t</span>ree <a hotkey='t' href='http://github.com/" + this.username + "/" +  this.repository + "/tree/" + this.commit.tree + "'>" + this.commit.tree + "</a><br/>";
    
    if (this.commit.parents[0])
      html += 
      "      <span>p</span>arent <a hotkey='p' href='http://github.com/" + this.username + "/" +  this.repository + "/tree/" + this.commit.parents[0].id + "'>" + this.commit.parents[0].id + "</a>";
    
    html += 
    "    </div>" + 
    "  </div>" + 
    "</div>";
    
    return html;
  }  
};