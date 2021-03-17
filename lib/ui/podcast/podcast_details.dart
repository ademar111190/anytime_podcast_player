// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/feed.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/podcast/funding_menu.dart';
import 'package:anytime/ui/podcast/playback_error_listener.dart';
import 'package:anytime/ui/podcast/podcast_context_menu.dart';
import 'package:anytime/ui/widgets/decorated_icon_button.dart';
import 'package:anytime/ui/widgets/delayed_progress_indicator.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/placeholder_builder.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:logging/logging.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// This Widget takes a search result and builds a list of currently available
/// podcasts. From here a user can option to subscribe/unsubscribe or play a
/// podcast directly from a search result.
class PodcastDetails extends StatefulWidget {
  final Podcast podcast;
  final PodcastBloc _podcastBloc;

  PodcastDetails(this.podcast, this._podcastBloc);

  @override
  _PodcastDetailsState createState() => _PodcastDetailsState();
}

class _PodcastDetailsState extends State<PodcastDetails> {
  final log = Logger('PodcastDetails');
  final ScrollController _sliverScrollController = ScrollController();
  var brightness = Brightness.dark;
  SystemUiOverlayStyle _systemOverlayStyle;
  bool toolbarCollpased = false;

  @override
  void initState() {
    super.initState();

    // Load the details of the Podcast specified in the URL
    log.fine('initState() - load feed');
    widget._podcastBloc.load(Feed(podcast: widget.podcast));

    // We only want to display the podcast title when the toolbar is in a
    // collapsed state. Add a listener and set toollbarCollapsed variable
    // as required. The text display property is then based on this boolean.
    _sliverScrollController.addListener(() {
      if (!toolbarCollpased && _sliverScrollController.hasClients && _sliverScrollController.offset > (300 - kToolbarHeight)) {
        setState(() {
          toolbarCollpased = true;
        });
      } else if (toolbarCollpased &&
          _sliverScrollController.hasClients &&
          _sliverScrollController.offset < (300 - kToolbarHeight)) {
        setState(() {
          toolbarCollpased = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    _systemOverlayStyle = SystemUiOverlayStyle(
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
      statusBarColor: Theme.of(context).appBarTheme.backgroundColor.withOpacity(toolbarCollpased ? 1.0 : 0.5),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    log.fine('_handleRefresh');

    widget._podcastBloc.load(Feed(
      podcast: widget.podcast,
      refresh: true,
    ));
  }

  void _resetSystemOverlayStyle() {
    setState(() {
      _systemOverlayStyle = SystemUiOverlayStyle(
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = PlaceholderBuilder.of(context);

    return WillPopScope(
      onWillPop: () {
        _resetSystemOverlayStyle();
        return Future.value(true);
      },
      child: Scaffold(
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          showChildOpacityTransition: false,
          child: CustomScrollView(
            controller: _sliverScrollController,
            slivers: <Widget>[
              SliverAppBar(
                backwardsCompatibility: false,
                systemOverlayStyle: _systemOverlayStyle,
                brightness: toolbarCollpased ? Theme.of(context).brightness : Brightness.dark,
                title: AnimatedOpacity(
                  opacity: toolbarCollpased ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Text(widget.podcast.title),
                ),
                leading: DecoratedIconButton(
                  icon: Icons.close,
                  iconColour: toolbarCollpased && Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).appBarTheme.foregroundColor
                      : Colors.white,
                  decorationColour: toolbarCollpased ? Color(0x00000000) : Color(0x22000000),
                  onPressed: () {
                    _resetSystemOverlayStyle();
                    Navigator.pop(context);
                  },
                ),
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                snap: false,
                flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                  tag: '${widget.podcast.imageUrl}:${widget.podcast.link}',
                  child: ExcludeSemantics(
                    child: StreamBuilder<BlocState<Podcast>>(
                        initialData: BlocEmptyState<Podcast>(),
                        stream: widget._podcastBloc.details,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          var podcast = widget.podcast;

                          // print('DEF: Image is ${podcast?.imageUrl}');

                          if (state is BlocLoadingState<Podcast>) {
                            // print('LOL: Image is ${state.data.imageUrl}');
                            podcast = state.data;
                          }

                          if (state is BlocPopulatedState<Podcast>) {
                            // print('POP: Image is ${state.results.imageUrl}');
                            podcast = state.results;
                          }

                          return PodcastHeaderImage(
                            podcast: podcast,
                            placeholderBuilder: placeholderBuilder,
                          );
                        }),
                  ),
                )),
              ),
              StreamBuilder<BlocState<Podcast>>(
                  initialData: BlocEmptyState<Podcast>(),
                  stream: widget._podcastBloc.details,
                  builder: (context, snapshot) {
                    final state = snapshot.data;

                    if (state is BlocLoadingState) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: <Widget>[
                              PlatformProgressIndicator(),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is BlocErrorState) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Theme.of(context).buttonColor,
                              ),
                              Text(
                                L.of(context).no_podcast_details_message,
                                style: Theme.of(context).textTheme.bodyText2,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is BlocPopulatedState<Podcast>) {
                      return SliverToBoxAdapter(
                          child: PlaybackErrorListener(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            PodcastTitle(state.results),
                            Divider(),
                          ],
                        ),
                      ));
                    }

                    return SliverToBoxAdapter(
                      child: Container(),
                    );
                  }),
              StreamBuilder<List<Episode>>(
                  stream: widget._podcastBloc.episodes,
                  builder: (context, snapshot) {
                    return snapshot.hasData
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return EpisodeTile(
                                episode: snapshot.data[index],
                                download: true,
                                play: true,
                              );
                            },
                            childCount: snapshot.data.length,
                            addAutomaticKeepAlives: false,
                          ))
                        : SliverToBoxAdapter(child: Container());
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class PodcastHeaderImage extends StatelessWidget {
  const PodcastHeaderImage({
    Key key,
    @required this.podcast,
    @required this.placeholderBuilder,
  }) : super(key: key);

  final Podcast podcast;
  final PlaceholderBuilder placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (podcast == null || podcast.imageUrl == null || podcast.imageUrl.isEmpty) {
      return Container(
        height: 560,
      );
    }

    return OptimizedCacheImage(
      useScaleCacheManager: true,
      width: 560,
      height: 560,
      imageUrl: podcast.imageUrl,
      fit: BoxFit.fitWidth,
      filterQuality: FilterQuality.medium,
      placeholder: (context, url) {
        return placeholderBuilder != null ? placeholderBuilder?.builder()(context) : DelayedCircularProgressIndicator();
      },
      errorWidget: (_, __, dynamic ___) {
        return placeholderBuilder != null
            ? placeholderBuilder?.errorBuilder()(context)
            : Placeholder(
                color: Theme.of(context).errorColor,
                strokeWidth: 1,
              );
      },
    );
  }
}

class PodcastTitle extends StatelessWidget {
  final Podcast podcast;

  PodcastTitle(this.podcast);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final _settingsBloc = Provider.of<SettingsBloc>(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(podcast.title ?? '', style: textTheme.headline6),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(podcast.copyright ?? '', style: textTheme.caption),
          ),
          Html(
            data: podcast.description ?? '',
            style: {'html': Style(fontWeight: textTheme.bodyText1.fontWeight)},
            onLinkTap: (url) => canLaunch(url).then((value) => launch(url)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SubscriptionButton(podcast),
                PodcastContextMenu(podcast),
                StreamBuilder<AppSettings>(
                  stream: _settingsBloc.settings,
                  builder: (context, settingsSnapshot) {
                    return (settingsSnapshot.hasData && settingsSnapshot.data.showFunding)
                        ? FundingMenu(podcast.funding)
                        : Container();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SubscriptionButton extends StatelessWidget {
  final Podcast podcast;

  SubscriptionButton(this.podcast);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<PodcastBloc>(context);

    return StreamBuilder<BlocState<Podcast>>(
        stream: bloc.details,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is BlocPopulatedState<Podcast>) {
              var p = state.results;

              return p.subscribed
                  ? OutlineButton.icon(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).buttonColor,
                      ),
                      label: Text(L.of(context).unsubscribe_label),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          useRootNavigator: false,
                          builder: (_) => BasicDialogAlert(
                            title: Text(L.of(context).unsubscribe_label),
                            content: Text(L.of(context).unsubscribe_message),
                            actions: <Widget>[
                              BasicDialogAction(
                                title: Text(
                                  L.of(context).cancel_button_label,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              BasicDialogAction(
                                title: Text(L.of(context).unsubscribe_button_label),
                                onPressed: () {
                                  bloc.podcastEvent(PodcastEvent.unsubscribe);

                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : OutlineButton.icon(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).buttonColor,
                      ),
                      label: Text(L.of(context).subscribe_label),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      onPressed: () {
                        bloc.podcastEvent(PodcastEvent.subscribe);
                      },
                    );
            }
          }
          return Container();
        });
  }
}
