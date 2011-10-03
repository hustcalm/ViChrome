vichrome.event = {};

vichrome.event.EventHandler =  function(m, v) {
    // dependencies
    var keyCodes         = vichrome.key.keyCodes,
        KeyManager       = vichrome.key.KeyManager,
        util             = vichrome.util,
        logger           = vichrome.log.logger,

    // private variables
        model = m,
        view  = v;

    function onBlur (e) {
        logger.d("onBlur");
        model.onBlur();
    }

    function onKeyDown (e) {
        var msg = getHandlableKey( e );
        if( msg ) {
            model.handleKey(msg);
        }
    }

    function onKeyPress (e) {
    }

    function onKeyUp (e) {
        view.notifyInputUpdated();
    }


    // decide whether to post the key event and do some pre-post process
    // return true if the key event can be posted.
    function getHandlableKey (e) {
        if( KeyManager.isOnlyModifier( e.keyIdentifier, e.ctrlKey,
                                       e.shiftKey, e.altKey, e.metaKey ) ) {
            return undefined;
        }

        var code = KeyManager.getLocalKeyCode( e.keyIdentifier, e.ctrlKey,
                                       e.shiftKey, e.altKey, e.metaKey );
        if( !code ){ return undefined; }

        if( model.prePostKeyEvent( code, e.ctrlKey, e.altKey, e.metaKey ) ) {
            return { code : code,
                     ctrl : e.ctrlKey,
                     alt  : e.altKey,
                     meta : e.metaKey };
        }
    }

    function onFocus (e) {
        logger.d("onFocus", e.target );
        model.onFocus( e.target );
    }

    function addWindowListeners() {
        window.addEventListener("keydown"    , onKeyDown    , true);
        window.addEventListener("keypress"   , onKeyPress   , true);
        window.addEventListener("keyup"      , onKeyUp      , true);
        window.addEventListener("focus"      , onFocus      , true);
        window.addEventListener("blur"       , onBlur       , true);
    }

    function init() {
        addWindowListeners();
        model.init();
    }

    // public APIs
    this.onInitEnabled = function(msg) {
        model.onInitEnabled( msg );
        init();
    };

    this.onCommandResponse = function (msg) {
        if( !msg ) { return; }
        // TODO
        if( msg.command === "Settings" ) {
            model.onSettings( msg );
        }
    };
};

