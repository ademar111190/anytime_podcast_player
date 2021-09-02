import 'package:anytime/bloc/podcast/audio_bloc.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/sleep_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class SleepSelector extends StatelessWidget {
  final Widget icon;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;

  const SleepSelector({
    Key key,
    this.icon,
    this.constraints,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioBloc = Provider.of<AudioBloc>(context, listen: false);
    final theme = Theme.of(context);
    final texts = L.of(context);

    return StreamBuilder<SleepPolicy>(
      stream: audioBloc.sleepPolicy,
      builder: (context, snapshot) {
        final sleepPolicy = snapshot.data ?? sleepPolicyOff();
        return IconButton(
          tooltip: texts.sleep_episode_function_header,
          constraints: constraints,
          padding: padding,
          icon: icon ??
              Icon(
                sleepPolicy is SleepPolicyOff
                    ? Icons.nightlight_outlined
                    : Icons.nightlight_round,
                size: 24.0,
                color: theme.buttonColor,
              ),
          onPressed: () {
            presentSleepPolicyOptions(
              context,
              theme,
              texts,
              audioBloc,
              sleepPolicy,
            );
          },
        );
      },
    );
  }

  void presentSleepPolicyOptions(
    BuildContext context,
    ThemeData theme,
    L texts,
    AudioBloc audioBloc,
    SleepPolicy sleepPolicy,
  ) {
    final options = sleepOptions(texts, sleepPolicy);
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            texts.playback_speed_label,
          ),
          scrollable: true,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                texts.cancel_button_label,
                style: TextStyle(color: theme.buttonColor),
              ),
            )
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(
              options.length,
              (int index) => dialogItemTile(
                context,
                theme,
                texts,
                audioBloc,
                sleepPolicy,
                options[index],
              ),
            ),
          ),
        );
      },
    );
  }

  void changeSleepPolicy(
    BuildContext context,
    L texts,
    AudioBloc audioBloc,
    SleepPolicy newPolicy,
  ) {
    audioBloc.changeSleepPolicy(newPolicy);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            newPolicy is SleepPolicyOff
                ? texts.sleep_episode_function_toggled_off
                : texts.sleep_episode_function_toggled_on,
          ),
        ),
      );
    }
    Navigator.pop(context);
  }

  List<SleepOption> sleepOptions(L texts, SleepPolicy sleepPolicy) {
    var options = <SleepOption>[];
    if (!(sleepPolicy is SleepPolicyOff)) {
      options.add(SleepOption(
        texts.sleep_episode_function_turn_off,
        sleepPolicyOff(),
      ));
    }
    options.addAll(
      [
        SleepOption(
          texts.sleep_episode_function_15_minutes,
          sleepPolicyMinutes(15),
        ),
        SleepOption(
          texts.sleep_episode_function_30_minutes,
          sleepPolicyMinutes(30),
        ),
        SleepOption(
          texts.sleep_episode_function_45_minutes,
          sleepPolicyMinutes(45),
        ),
        SleepOption(
          texts.sleep_episode_function_60_minutes,
          sleepPolicyMinutes(60),
        ),
      ],
    );
    return options;
  }

  Widget dialogItemTile(
    BuildContext context,
    ThemeData theme,
    L texts,
    AudioBloc audioBloc,
    SleepPolicy groupValue,
    SleepOption option,
  ) {
    return InkWell(
      highlightColor: theme.buttonColor.withAlpha(50),
      onTap: () {
        changeSleepPolicy(context, texts, audioBloc, option.policy);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Row(
          children: <Widget>[
            Radio<SleepPolicy>(
              groupValue: groupValue,
              value: option.policy,
              onChanged: (newValue) {
                if (newValue != null) {
                  changeSleepPolicy(context, texts, audioBloc, newValue);
                }
              },
              fillColor: theme.radioTheme.fillColor,
            ),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepOption {
  final String label;
  final SleepPolicy policy;

  const SleepOption(
    this.label,
    this.policy,
  );
}
