g = this

$.fn.extend {
    isWithinScreen : ->
        offset = $(@).offset()
        unless offset? then return false

        padding = 10
        if offset.left + padding > window.pageXOffset + window.innerWidth or \
           offset.left - padding < window.pageXOffset
            return false

        if offset.top + padding > window.pageYOffset + window.innerHeight or \
           offset.top - padding < window.pageYOffset
            return false

        return true

    scrollTo : (x, y, speed=80) ->
        offset = $($(@).get(0)).offset()
        unless x? or y?
            unless offset? then return $(@)
            if $(@).isWithinScreen() then return $(@)

        newX = offset.left - window.innerWidth / 2
        newY = offset.top - window.innerHeight / 2

        if newX > document.body.scrollLeft - window.innerWidth
            newX - document.body.scrollLeft - window.innerWidth

        if newY > document.body.scrollHeight - window.innerHeight
            newX = document.body.scrollHeight - window.innerHeight

        left = x ? newX
        top  = y ? newY

        unless g.model.getSetting "smoothScroll"
            speed = 0

        $(document.body).animate( {scrollTop : top, scrollLeft : left}, speed )
        return $(@)

    scrollBy : (x=0, y=0, speed=35) ->
        top  = window.pageYOffset  + y
        left = window.pageXOffset  + x

        unless g.model.getSetting "smoothScroll"
            speed = 0

        $(document.body).animate( {scrollTop : top, scrollLeft : left}, speed )
        return $(@)
}

class g.Surface
    init : ->
        align = g.model.getSetting "commandBoxAlign"
        width = g.model.getSetting "commandBoxWidth"
        alignClass = "vichrome-statusline" + align

        @statusLine = $( '<div id="vichromestatusline" />' )
                      .addClass( 'vichrome-statuslineinactive' )
                      .addClass( alignClass )
                      .width( width )

        @hideStatusLine()
        @attach( @statusLine )
        @initialized = true

    attach : (w) ->
        $(document.body).append( w )
        this

    activeStatusLine : ->
        @statusLine.removeClass( 'vichrome-statuslineinactive' )
        @statusLine.show()

        if @slTimeout
            clearTimeout( @slTimeout )
            @slTimeout = undefined

        this

    inactiveStatusLine : ->
        @statusLine.addClass( 'vichrome-statuslineinactive' )
        return this

    hideStatusLine : ->
        if @slTimeout?
            clearTimeout( @slTimeout )
            @slTimeout = undefined

        @statusLine.html("").hide()
        this

    setStatusLineText : (text, timeout) ->
        @statusLine.html( text )
        @activeStatusLine()

        if timeout
            @slTimeout = setTimeout ( => @statusLine.html("").hide() ), timeout

        this

    detach : (w) -> w.detach()

    focusInput : (idx) ->
        unless @initialized then return this

        $('form input:text:visible').scrollTo?().get(0)?.focus()
        this

    scrollBy : (x, y) ->
        unless@initialized then return this

        $(document.body).scrollBy(x, y, 20)
        this

    scrollTo : (x, y) ->
        unless @initialized then return this

        $(document.body).scrollTo(x, y, 80)
        this

    backHist : ->
        unless @initialized then return this

        window.history.back()
        this

    forwardHist : ->
        unless @initialized then return this
        window.history.forward()
        this

    reload : ->
        unless @initialized then return this

        window.location.reload()
        this

    blurActiveElement : ->
        unless @initialized then return this

        document.activeElement.blur()
        this

class g.CommandBox
    constructor : ->
        @inputListeners = []

    init : (@view, @align, @width) ->
        alignClass = "vichrome-vichromebox" + @align

        @box   = $( '<div id="vichromebox" />' )
                 .addClass( alignClass )
                 .width( @width )

        @input = $( '<input type="text" id="vichromeinput" spellcheck="false" value="" />' )
        @modeChar  = $( '<div id="vichromemodechar" />' )
        @inputField = $( '<div id="vichromefield" />' )
                      .append( @modeChar )
                      .append( $('<div id="vichromeinput" />').append(@input) )
        @box.append( @inputField )

        this

    addInputUpdateListener : (fn) ->
        @inputListeners.push( fn )
        this

    attachTo : (view) ->
        view.attach( @box )
        this

    detachFrom : (view) ->
        view.detach( @box )
        if @candidateBox?
            @candidateBox.stop()
            @candidateBox.detachFrom( view )
        this

    show : (modeChar, input) ->
        @input.attr( "value", input )
        @modeChar.html( modeChar )

        @box.show()
        @inputField.show()

        $(document).keyup (e) =>
            val = @input.val()
            if @selectedCand == val then return

            if @bfInput != val and @isVisible()
                listener( val ) for listener in @inputListeners

            @bfInput = val

        @view.activeStatusLine()
        this

    hide : ->
        if @isVisible()
            @inputField.hide()
            @input.blur()

        @box.unbind()
        this

    focus : ->
        @input.get(0)?.focus()
        this

    isVisible : -> @inputField.css( 'display' ) isnt 'none'

    value : (a) ->
        if a?
            @input.val(a)
        else
            return @input.val()

    setCandidateBox : (candBox) ->
        unless g.model.getSetting "enableCompletion" then return this
        if @candidateBox?
            @candidateBox.stop()
            @candidateBox.detachFrom( view )

        @candidateBox = candBox.init(@align, @width)
        @candidateBox.setCommandBox this
        @candidateBox.attachTo(@view).show()
        this

    nextCandidate : ->
        if @candidateBox?
            focused = @candidateBox.focusNext()
            @selectedCand = focused.value ? focused.str
            @value( @selectedCand  )
        this

    prevCandidate : ->
        if @candidateBox?
            focused = @candidateBox?.focusPrev()
            @selectedCand = focused.value ? focused.str
            @value( @selectedCand  )
        this

class g.CandidateBox
    itemHeight  : 22
    winColumns  : 20
    constructor : ->
        @items   = {}
        @sources = {}
        @selectedListeners = []
        @index    = 0
        @scrIndex = 0

    init : (@align, @width)->
        alignClass = "vichrome-candbox" + @align
        @box = $( '<div id="vichromecandbox" />' )
               .addClass( alignClass )
               .css( 'min-width', @width )
        this

    show : ->
        @box.show()
        this

    hide : ->
        @box.hide()
        this

    addItem : (id, item) ->
        @items[id].push(item)
        this

    getItemCnt : ->
        result = 0
        result += items.length for src,items of @items
        result


    addSource : (src) ->
        @sources[src.id] = src
        @items[src.id] = []
        src.addSrcUpdatedListener( (items) =>
            @items[src.id] = items
            @update(src.id)
        )
        this

    attachTo : (view) ->
        view.attach( @box )
        this

    detachFrom : (view) ->
        view.detach( @box )
        this

    resetItem : ->
        @candidates = []
        this

    makeItemLine : (src, id, item) ->
        line = $("<div id=\"vichromecanditem\" source=\"#{src}\" num=\"#{id}\" />")
        text = $("<div class=\"vichrome-candtext\" />").html( item.str )
        dscr = $("<div class=\"vichrome-canddscr\" />").html( item.dscr )
        srcType = $("<div class=\"vichrome-canddscr\" />").html( item.source )
        line.append( text ).append( srcType ).append( dscr )
        if item.value?
            line.attr("value", item.value)
        line

    update : (id)->
        $('#vichromecanditem'+"[source=#{id}]").remove()
        for item, i in @items[id]
            @box.append( @makeItemLine(id, i, item) )
        this

    getItem : (id, num) -> @items[id][num]

    scrollTo   : (@scrIndex) -> @box.get(0).scrollTop = @itemHeight * @scrIndex
    scrollDown : ->
        if @index >= @scrIndex + @winColumns
            @scrollTo( @scrIndex+1 )
        else if @index < @scrIndex
            @scrollTo( @index )
    scrollUp   : ->
        if @index >= @scrIndex + @winColumns
            @scrollTo(@getItemCnt() - @winColumns)
        else if @index < @scrIndex
            @scrollTo( @index )

    getFocusedValue : -> @focusedValue
    setFocusedValue : (@focusedValue) ->

    scrollTop  : -> @scrollTo( 0 )
    scrollBottom : ->
        @scrIndex = 0
        @box.get(0).scrollTop = 0

    removeFocus : ($focused) ->
        $focused.removeClass("vichrome-canditemfocused")
        $focused.children().removeClass("vichrome-canditemfocused")

    setFocus : ( $settee ) ->
        $settee.addClass("vichrome-canditemfocused")
        $settee.children().addClass("vichrome-canditemfocused")
        if (val = $settee.attr("value"))
            @setFocusedValue( val )

    focusNext : ->
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @removeFocus( $focused )
        $next = $focused.next()
        @index++
        if $next.attr("id") isnt "vichromecanditem"
            @index = 0
            $next = $("#vichromecanditem:first-child").first()

        @scrollDown()
        @setFocus( $next )
        @getItem( $next.attr("source"), parseInt( $next.attr("num") ) )

    focusPrev : ->
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @removeFocus( $focused )
        $next = $focused.prev()
        @index--
        if $next.attr("id") isnt "vichromecanditem"
            $next = $("#vichromecanditem:last-child").last()
            @index = @getItemCnt() - 1

        @scrollUp()
        @setFocus( $next )
        @getItem( $next.attr("source"), parseInt( $next.attr("num") ) )

    getFocused : ->
        $focused = $("#vichromecanditem.vichrome-canditemfocused")
        @getItem( $focused.attr("source"), parseInt( $focused.attr("num") ) )

    onInput : (word) ->
        if @stopped then return
        src.cbInputUpdated word for id, src of @sources
        return

    setCommandBox : (box) ->
        box.addInputUpdateListener( (word) => @onInput word )
        this

    stop : ->
        @stopped = true


class g.CandidateSource
    constructor : (@maxItems=5)->
        @updatedListeners = []
        @items = []

    addSrcUpdatedListener : (listener) ->
        @updatedListeners.push( listener )
        this

    addItem : (item) ->
        @items.push( item ) if @items.length <= @maxItems

    resetItem : ->
        @items = []

    notifyUpdated : ->
        listener( @items ) for listener in @updatedListeners
        this

    cbInputUpdated : (word) ->
        if @timer? then clearTimeout @timer
        @timer = setTimeout( =>
            @timer = null
            @onInput?(word)
        , 200)

class g.CandSourceCommand extends g.CandidateSource
    id : "Command"
    onInput : (word) ->
        unless word.length > 0 then return
        @resetItem()
        for com,method of g.CommandExecuter::commandTable
            if com.toUpperCase().slice( 0, word.length ) == word.toUpperCase()
                @addItem(
                    str    : com
                    source : "Command"
                    dscr   : ""
                )

        @notifyUpdated()

class g.CandSourceAlias extends g.CandidateSource
    id : "Alias"
    onInput : (word) ->
        unless word.length > 0 then return
        @resetItem()
        for alias, com of g.model.getAlias()
            if alias.toUpperCase().slice( 0, word.length ) == word.toUpperCase()
                @addItem(
                    str    : alias
                    source : "Alias"
                    dscr   : com
                )

        @notifyUpdated()

class g.CandSourceHistory extends g.CandidateSource
    id : "WebHistory"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        chrome.extension.sendRequest( {
            command : "GetHistory"
            value   : word
        }, (items) =>
            for item in items
                @addItem(
                    str    : item.title
                    source : "History"
                    dscr   : item.url
                    value  : item.url
                )
            @notifyUpdated()
        )

class g.CandSourceBookmark extends g.CandidateSource
    id : "Bookmark"
    onInput : (word) ->
        unless word.length > 0 then return

        @resetItem()
        chrome.extension.sendRequest( {
            command : "GetBookmark"
            value   : word
        }, (nodes) =>
            for node in nodes
                @addItem(
                    str    : node.title
                    source : "Bookmark"
                    dscr   : node.url
                    value  : node.url
                )
            @notifyUpdated()
        )

class g.CandSourceSearchHist extends g.CandidateSource
    id : "SearchHistory"
    constructor : ->
        super()
        chrome.extension.sendRequest( {
            command : "GetSearchHistory"
        }, (msg) => @history = msg.value.reverse() )

    onInput : (word) ->
        unless @history? then return

        @resetItem()
        for hist in @history
            if hist.toUpperCase().slice( 0, word.length ) == word.toUpperCase()
                @addItem(
                    str    : hist
                    source : "Search History"
                    dscr   : ""
                )

        @notifyUpdated()

class g.CandSourceGoogleSuggest extends g.CandidateSource
    id : "GoogleSuggest"
    onInput : (word) ->
