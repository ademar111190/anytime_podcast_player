// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/funding.dart';
import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart' as search;

import 'episode.dart';

class Podcast {
  int id;
  final String guid;
  final String url;
  final String link;
  final String title;
  final String description;
  final String imageUrl;
  final String thumbImageUrl;
  final String copyright;
  final List<Funding> funding;
  DateTime subscribedDate;
  List<Episode> episodes;
  Map<String, dynamic> metadata;

  Podcast({
    @required this.guid,
    @required this.url,
    @required this.link,
    @required this.title,
    this.id,
    this.description,
    this.imageUrl,
    this.thumbImageUrl,
    this.copyright,
    this.subscribedDate,
    this.funding,
    this.episodes,
    this.metadata,
  }) {
    episodes ??= [];
  }

  Podcast.fromSearchResultItem(search.Item item)
      : guid = item.guid,
        url = item.feedUrl,
        link = item.feedUrl,
        title = item.trackName,
        description = '',
        imageUrl = item.bestArtworkUrl ?? item.artworkUrl,
        thumbImageUrl = item.thumbnailArtworkUrl,
        funding = const <Funding>[],
        copyright = item.artistName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guid': guid,
      'title': title ?? '',
      'copyright': copyright ?? '',
      'description': description ?? '',
      'url': url,
      'imageUrl': imageUrl ?? '',
      'thumbImageUrl': thumbImageUrl ?? '',
      'subscribedDate': subscribedDate?.millisecondsSinceEpoch.toString() ?? '',
      'funding': (funding ?? <Funding>[]).map((funding) => funding.toMap())?.toList(growable: false),
      'metadata': metadata,
    };
  }

  static Podcast fromMap(int key, Map<String, dynamic> podcast) {
    final sds = podcast['subscribedDate'] as String;
    final funding = <Funding>[];
    var sd = DateTime.now();

    if (sds != null && sds.isNotEmpty && int.tryParse(sds) != null) {
      sd = DateTime.fromMicrosecondsSinceEpoch(int.parse(sds));
    }

    if (podcast['funding'] != null) {
      for (var chapter in (podcast['funding'] as List)) {
        if (chapter is Map<String, dynamic>) {
          funding.add(Funding.fromMap(chapter));
        }
      }
    }

    return Podcast(
      id: key,
      guid: podcast['guid'] as String,
      link: podcast['link'] as String,
      title: podcast['title'] as String,
      copyright: podcast['copyright'] as String,
      description: podcast['description'] as String,
      url: podcast['url'] as String,
      imageUrl: podcast['imageUrl'] as String,
      thumbImageUrl: podcast['thumbImageUrl'] as String,
      funding: funding,
      subscribedDate: sd,
      metadata: podcast['metadata'] as Map<String, dynamic>,
    );
  }

  bool get subscribed => id != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Podcast && runtimeType == other.runtimeType && guid == other.guid && url == other.url;

  @override
  int get hashCode => guid.hashCode ^ url.hashCode;
}
