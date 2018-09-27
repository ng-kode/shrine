import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'model/product.dart';
import 'login.dart';

class Backdrop extends StatefulWidget {
  final Category currentCategory;
  final Widget frontLayer;
  final Widget backLayer;
  final Widget frontTitle;
  final Widget backTitle;

  Backdrop({
    @required this.currentCategory,
    @required this.frontLayer,
    @required this.backLayer,
    @required this.frontTitle,
    @required this.backTitle
  }) :  assert(currentCategory != null),
        assert(frontLayer != null),
        assert(backLayer != null),
        assert(frontTitle != null),
        assert(backLayer != null);

  @override
  State<StatefulWidget> createState() {
    return _BackdropState();
  }
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      elevation: 0.0,
      title: _BackdropTitle(
        listenable: _ctrl.view,
        onPress: _toggleBackdropLayerVisibility,
        frontTitle: widget.frontTitle,
        backTitle: widget.backTitle,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.search,
            semanticLabel: 'search',
          ),
          onPressed: () {
            print('Search button');
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
          }
        ),
        IconButton(
          icon: Icon(Icons.tune, semanticLabel: 'filter',),
          onPressed: () { print('Filter button'); }
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: LayoutBuilder(builder: _buildStack),
    );
  }

  // body stack
  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final double layoutTitleHeight = 48.0;
    final Size layerSize = constraints.biggest;
    final double layerTop = layerSize.height - layoutTitleHeight;

    Animation<RelativeRect> layerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, layerTop, 0.0, layerTop - layerSize.height),
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0)
    ).animate(_ctrl.view);

    return Stack(
      key: _backdropKey,
      children: <Widget>[
        ExcludeSemantics(
          child: widget.backLayer,
          excluding: _frontLayerVisible,
        ),
        PositionedTransition(
          rect: layerAnimation,
          child: _FrontLayer(
            child: widget.frontLayer,
            onTap: _toggleBackdropLayerVisibility,
          ),
        )
      ]
    );
  }

  // Animation stuff
  AnimationController _ctrl;
  final double _kFlingVelocity = 2.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(Backdrop old) {
    super.didUpdateWidget(old);

    if (widget.currentCategory != old.currentCategory) {
      _toggleBackdropLayerVisibility();
    } else if (!_frontLayerVisible) {
      _ctrl.fling(velocity: _kFlingVelocity);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _ctrl.status;
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _ctrl.fling(
      velocity:  _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final Function onPress;
  final Widget frontTitle;
  final Widget backTitle;

  _BackdropTitle({
    Key key,
    Listenable listenable,
    this.onPress,
    @required this.frontTitle,
    @required this.backTitle,
  }) :  assert(frontTitle != null),
        assert(backTitle != null),
        super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.listenable;

    return DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Row(
        children: <Widget>[
          // branded icon
          SizedBox(
            width: 72.0,
            child: IconButton(
            padding: EdgeInsets.only(right: 8.0),
            onPressed: this.onPress,
            icon: Stack(
              children: <Widget>[
                Opacity(
                  opacity: animation.value,
                  child: ImageIcon(AssetImage('assets/slanted_menu.png')),
                ),
                FractionalTranslation(
                  translation: Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(1.0, 0.0)
                  ).evaluate(animation),
                  child: ImageIcon(AssetImage('assets/diamond.png')),
                )
              ],
            )
            )
          ),
          // title
          Stack(
            children: <Widget>[
              Opacity(
                opacity: CurvedAnimation(
                  parent: ReverseAnimation(animation),
                  curve: Interval(0.5, 1.0,),
                ).value,
                child: FractionalTranslation(
                  translation: Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(0.5, 0.0)
                  ).evaluate(animation),
                  child: backTitle,
                ),
              ),
              Opacity(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Interval(0.5, 1.0,),
                ).value,
                child: FractionalTranslation(
                  translation: Tween<Offset>(
                    begin: Offset(-0.25, 0.0),
                    end: Offset.zero
                  ).evaluate(animation),
                  child: frontTitle,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// front layer corner-cut and elevation
class _FrontLayer extends StatelessWidget {
  _FrontLayer({
    Key key,
    this.child,
    this.onTap
  }) : super(key: key);

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16.0,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(46.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
             height: 40.0,
             alignment: AlignmentDirectional.centerStart,
            ),
          ),
          Expanded(
            child: child,
          )
        ],
      ),
    );
  }
}