/*! smooth-scroll v7.1.1 | (c) 2015 Chris Ferdinandi | MIT License | http://github.com/cferdinandi/smooth-scroll */
!function(e,t){"function"==typeof define&&define.amd?define([],t(e)):"object"==typeof exports?module.exports=t(e):e.smoothScroll=t(e)}("undefined"!=typeof global?global:this.window||this.global,function(e){"use strict";var t,n,o,r,a={},u="querySelector"in document&&"addEventListener"in e,c={selector:"[data-scroll]",selectorHeader:"[data-scroll-header]",speed:500,easing:"easeInOutCubic",offset:0,updateURL:!0,callback:function(){}},i=function(){var e={},t=!1,n=0,o=arguments.length;"[object Boolean]"===Object.prototype.toString.call(arguments[0])&&(t=arguments[0],n++);for(var r=function(n){for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(t&&"[object Object]"===Object.prototype.toString.call(n[o])?e[o]=i(!0,e[o],n[o]):e[o]=n[o])};o>n;n++){var a=arguments[n];r(a)}return e},s=function(e){return Math.max(e.scrollHeight,e.offsetHeight,e.clientHeight)},l=function(e,t){var n,o,r=t.charAt(0),a="classList"in document.documentElement;for("["===r&&(t=t.substr(1,t.length-2),n=t.split("="),n.length>1&&(o=!0,n[1]=n[1].replace(/"/g,"").replace(/'/g,"")));e&&e!==document;e=e.parentNode){if("."===r)if(a){if(e.classList.contains(t.substr(1)))return e}else if(new RegExp("(^|\\s)"+t.substr(1)+"(\\s|$)").test(e.className))return e;if("#"===r&&e.id===t.substr(1))return e;if("["===r&&e.hasAttribute(n[0])){if(!o)return e;if(e.getAttribute(n[0])===n[1])return e}if(e.tagName.toLowerCase()===t)return e}return null},f=function(e){for(var t,n=String(e),o=n.length,r=-1,a="",u=n.charCodeAt(0);++r<o;){if(t=n.charCodeAt(r),0===t)throw new InvalidCharacterError("Invalid character: the input contains U+0000.");a+=t>=1&&31>=t||127==t||0===r&&t>=48&&57>=t||1===r&&t>=48&&57>=t&&45===u?"\\"+t.toString(16)+" ":t>=128||45===t||95===t||t>=48&&57>=t||t>=65&&90>=t||t>=97&&122>=t?n.charAt(r):"\\"+n.charAt(r)}return a},d=function(e,t){var n;return"easeInQuad"===e&&(n=t*t),"easeOutQuad"===e&&(n=t*(2-t)),"easeInOutQuad"===e&&(n=.5>t?2*t*t:-1+(4-2*t)*t),"easeInCubic"===e&&(n=t*t*t),"easeOutCubic"===e&&(n=--t*t*t+1),"easeInOutCubic"===e&&(n=.5>t?4*t*t*t:(t-1)*(2*t-2)*(2*t-2)+1),"easeInQuart"===e&&(n=t*t*t*t),"easeOutQuart"===e&&(n=1- --t*t*t*t),"easeInOutQuart"===e&&(n=.5>t?8*t*t*t*t:1-8*--t*t*t*t),"easeInQuint"===e&&(n=t*t*t*t*t),"easeOutQuint"===e&&(n=1+--t*t*t*t*t),"easeInOutQuint"===e&&(n=.5>t?16*t*t*t*t*t:1+16*--t*t*t*t*t),n||t},m=function(e,t,n){var o=0;if(e.offsetParent)do o+=e.offsetTop,e=e.offsetParent;while(e);return o=o-t-n,o>=0?o:0},h=function(){return Math.max(e.document.body.scrollHeight,e.document.documentElement.scrollHeight,e.document.body.offsetHeight,e.document.documentElement.offsetHeight,e.document.body.clientHeight,e.document.documentElement.clientHeight)},p=function(e){return e&&"object"==typeof JSON&&"function"==typeof JSON.parse?JSON.parse(e):{}},g=function(t,n){e.history.pushState&&(n||"true"===n)&&"file:"!==e.location.protocol&&e.history.pushState(null,null,[e.location.protocol,"//",e.location.host,e.location.pathname,e.location.search,t].join(""))},b=function(e){return null===e?0:s(e)+e.offsetTop};a.animateScroll=function(t,n,a){var u=p(t?t.getAttribute("data-options"):null),s=i(s||c,a||{},u);n="#"+f(n.substr(1));var l="#"===n?e.document.documentElement:e.document.querySelector(n),v=e.pageYOffset;o||(o=e.document.querySelector(s.selectorHeader)),r||(r=b(o));var y,O,S,I=m(l,r,parseInt(s.offset,10)),H=I-v,E=h(),L=0;g(n,s.updateURL);var j=function(o,r,a){var u=e.pageYOffset;(o==r||u==r||e.innerHeight+u>=E)&&(clearInterval(a),l.focus(),s.callback(t,n))},w=function(){L+=16,O=L/parseInt(s.speed,10),O=O>1?1:O,S=v+H*d(s.easing,O),e.scrollTo(0,Math.floor(S)),j(S,I,y)},C=function(){y=setInterval(w,16)};0===e.pageYOffset&&e.scrollTo(0,0),C()};var v=function(e){var n=l(e.target,t.selector);n&&"a"===n.tagName.toLowerCase()&&(e.preventDefault(),a.animateScroll(n,n.hash,t))},y=function(e){n||(n=setTimeout(function(){n=null,r=b(o)},66))};return a.destroy=function(){t&&(e.document.removeEventListener("click",v,!1),e.removeEventListener("resize",y,!1),t=null,n=null,o=null,r=null)},a.init=function(n){u&&(a.destroy(),t=i(c,n||{}),o=e.document.querySelector(t.selectorHeader),r=b(o),e.document.addEventListener("click",v,!1),o&&e.addEventListener("resize",y,!1))},a});

$(document).ready(function() {

var MAX_HEADER_DEPTH = 3
var scrolling = false
var scrollTimeout
var activeLink = document.querySelector('.sidebar-link.current')
var allLinks = []

// create sub links for h2s
var h2s = document.querySelectorAll('h2')

// find all h3s and nest them under their h2s
var h3s = document.querySelectorAll('h3')

var isAfter = function(e1, e2) {
  return e1.compareDocumentPosition(e2) & Node.DOCUMENT_POSITION_FOLLOWING;
}

var h2sWithH3s = [];
var j = 0;
for (var i = 0; i < h2s.length; i++) {
  var h2 = h2s[i];
  var nextH2 = h2s[i+1];
  var ourH3s = [];
  while (h3s[j] && isAfter(h2, h3s[j]) && (!nextH2 || !isAfter(nextH2, h3s[j]))) {
    ourH3s.push({ header: h3s[j] });
    j++;
  }

  h2sWithH3s.push({
    header: h2,
    subHeaders: ourH3s
  });
}

if (h2sWithH3s.length) {
  createSubMenu(activeLink.parentNode, h2sWithH3s)
  smoothScroll.init({
    speed: 400,
    offset: window.innerWidth > 560 ? 115 : 55,
    callback: function () {
      scrolling = false
    }
  })
}

function createSubMenu (container, headers) {
  var subMenu = document.createElement('ul')
  subMenu.className = 'sub-menu'
  container.appendChild(subMenu)
  Array.prototype.forEach.call(headers, function (h) {
    var link = createSubMenuLink(h.header)
    subMenu.appendChild(link)
    if (h.subHeaders) {
      createSubMenu(link, h.subHeaders)
    }
    makeHeaderLinkable(h.header)
  })
}

function createSubMenuLink (h) {
  allLinks.push(h)
  var headerLink = document.createElement('li')
  headerLink.innerHTML =
    '<a href="#' + h.id + '" data-scroll class="' + h.tagName + '">' + (h.title || h.textContent) + '</a>'
  headerLink.firstChild.addEventListener('click', onLinkClick)
  return headerLink
}

function makeHeaderLinkable (h) {
  var anchor = document.createElement('a')
  anchor.className = 'anchor'
  anchor.href = '#' + h.id
  anchor.setAttribute('aria-hidden', true)
  anchor.setAttribute('data-scroll', '')
  anchor.textContent = '🔗'
  anchor.addEventListener('click', onLinkClick)
  h.insertBefore(anchor, h.firstChild)
}

function onLinkClick (e) {
  if (document.querySelector('.sub-menu').contains(e.target)) {
    setActive(e.target)
  }
  scrolling = true
  document.body.classList.remove('sidebar-open')
}

// setup active h3 update
window.addEventListener('scroll', updateSidebar)
window.addEventListener('resize', updateSidebar)

function updateSidebar () {
  if (scrolling) return
  var doc = document.documentElement
  var top = doc && doc.scrollTop || document.body.scrollTop
  var last
  for (var i = 0; i < allLinks.length; i++) {
    var link = allLinks[i]
    if (link.offsetTop - 120 > top) {
      if (!last) last = link
      break
    } else {
      last = link
    }
  }
  if (last) {
    setActive(last)
  }
}

function setActive (link) {
  var previousActive = document.querySelector('.sub-menu .active')
  var id = link.id || link.hash.slice(1)
  var currentActive = document.querySelector('.sub-menu a[href="#' + id + '"]')
  if (currentActive !== previousActive) {
    if (previousActive) previousActive.classList.remove('active')
    currentActive.classList.add('active')
  }
}
});
