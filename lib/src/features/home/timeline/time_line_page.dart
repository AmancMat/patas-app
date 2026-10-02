import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/home/timeline/timeline_provider.dart';
import 'package:patas_web_app/src/features/home/timeline/story_widget.dart';
import 'package:patas_web_app/src/features/home/timeline/widgets/essencial_summary_widget.dart';
import 'package:patas_web_app/src/features/home/timeline/widgets/events_feed_highlight_widget.dart';
import 'package:patas_web_app/src/features/home/widgets/home_quick_post_card.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../profile/publish_widget.dart';

class TimeLinePage extends StatefulWidget {
  const TimeLinePage({super.key});

  @override
  State<TimeLinePage> createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimelineProvider>(context, listen: false).loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineProvider = Provider.of<TimelineProvider>(context);
    final thmode = Provider.of<DarkMode>(context);

    // Altura do container de stories: sempre fixa, independente da proporção da tela
    const double storyHeight = 150.0;

    Widget feedContent = RefreshIndicator(
      onRefresh: () => timelineProvider.loadTimeline(),
      color: AppColors.patasColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Quick Post Card (Estilo Facebook)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: const HomeQuickPostCard(),
            ),
          ),
          // Stories
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: Container(
                height: storyHeight,
                width: double.infinity,
                color: thmode.darkMode ? AppColors.bodygray : const Color(0xffF5F5F5),
                padding: const EdgeInsets.only(bottom: 8, left: 10),
                margin: const EdgeInsets.only(top: 4, bottom: 0),
                child: StoryWidget(
                  stories: timelineProvider.stories,
                  isLoading: timelineProvider.isLoading,
                  errorMessage: timelineProvider.error,
                  onRetry: () => timelineProvider.loadTimeline(),
                  onStoryCreated: () => timelineProvider.loadTimeline(silent: true),
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: const EssencialSummaryWidget(),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: const EventsFeedHighlightWidget(),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: PublishWidget(
                posts: timelineProvider.posts,
                isLoading: timelineProvider.isLoading,
                errorMessage: timelineProvider.error,
                onRetry: () => timelineProvider.loadTimeline(),
                onActionComplete: () => timelineProvider.loadTimeline(silent: true),
              ),
            ),
          ),
          // Fim do feed (apenas se houver posts exibidos)
          if (timelineProvider.posts.isNotEmpty)
            Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth:
                      context.isDesktop ? Breakpoints.feedMaxWidth : double.infinity),
              child: Container(
            color: thmode.darkMode ? AppColors.bodygray : const Color(0xffF5F5F5),
            margin: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(top: 60, left: 64, right: 64),
                  child: Text(
                    'Você chegou ao fim das novidades!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: thmode.darkMode
                            ? Colors.white
                            : AppColors.darkBG,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ),
                Container(
                    margin: const EdgeInsets.only(
                        top: 20, bottom: 26, left: 16, right: 16),
                    child: Image.asset('assets/end_of_feed.png')),
                Container(
                  margin: const EdgeInsets.only(
                      top: 20, bottom: 80, left: 32, right: 32),
                  child: Text(
                    'Que tal encontrar novos amigos para o seu pet? Explore a comunidade e descubra perfis incríveis para seguir!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: thmode.darkMode
                            ? Colors.white
                            : AppColors.darkBG,
                        fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          ),
          ),
        ],
      ),
    );

    return Container(
      color: thmode.darkMode ? AppColors.bodygray : const Color(0xffF5F5F5),
      child: feedContent, // A ListView agora ocupa o bloco inteiro (capturando mouse), e os items de dentro dela é que definem sua largura limitada
    );
  }
}
