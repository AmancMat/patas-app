import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/profile/publish_widget.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:patas_web_app/src/features/pets/services/follow_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/main.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/edit_ong_profile_screen.dart';
import 'package:patas_web_app/src/features/ongs_corp/edit_corp_profile.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';

class OrgProfilePage extends StatefulWidget {
  final OngProfile? ong;
  final CorpProfile? corp;
  final String? ongId;
  final String? corpId;

  const OrgProfilePage({
    super.key,
    this.ong,
    this.corp,
    this.ongId,
    this.corpId,
  });

  @override
  State<OrgProfilePage> createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage> {
  final PostService _postService = PostService();
  final FollowService _followService = FollowService();
  final OngService _ongService = OngService();
  final CorpService _corpService = CorpService();

  OngProfile? _ong;
  CorpProfile? _corp;

  Future<List<Post>>? _postsFuture;
  bool _isDataLoaded = false;
  bool _isFollowing = false;
  int _followersCount = 0;

  bool get _isOwner {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      if (_ong?.userId.isNotEmpty == true && _ong!.userId == currentUserId) {
        return true;
      }
      if (_corp?.userId.isNotEmpty == true && _corp!.userId == currentUserId) {
        return true;
      }
    }
    final activeAccount =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    if (activeAccount != null) {
      if (_ong?.id != null && activeAccount.id == _ong!.id) {
        return true;
      }
      if (_corp?.id != null && activeAccount.id == _corp!.id) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _ong = widget.ong;
    _corp = widget.corp;
    _postsFuture = _postService.getPosts(
      ongId: _ong?.id ?? widget.ongId,
      companyId: _corp?.id ?? widget.corpId,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    _loadPosts();
    _checkFollowingStatus();
    _loadFollowersCount();

    final effectiveOngId = _ong?.id ?? widget.ongId;
    if (effectiveOngId != null && effectiveOngId.isNotEmpty) {
      final fullOng = await _ongService.getOngProfileById(effectiveOngId);
      if (fullOng != null && mounted) {
        setState(() {
          _ong = fullOng;
        });
      }
    }

    final effectiveCorpId = _corp?.id ?? widget.corpId;
    if (effectiveCorpId != null && effectiveCorpId.isNotEmpty) {
      final fullCorp = await _corpService.getCorpProfileById(effectiveCorpId);
      if (fullCorp != null && mounted) {
        setState(() {
          _corp = fullCorp;
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    final future = _postService.getPosts(
      ongId: _ong?.id ?? widget.ongId,
      companyId: _corp?.id ?? widget.corpId,
    );
    setState(() {
      _postsFuture = future;
    });
    await future;
    if (mounted) {
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  Future<void> _checkFollowingStatus() async {
    final status = await _followService.isFollowingOrg(
      ongId: _ong?.id ?? widget.ongId,
      companyId: _corp?.id ?? widget.corpId,
    );
    if (mounted) {
      setState(() => _isFollowing = status);
    }
  }

  Future<void> _loadFollowersCount() async {
    final count = await _followService.getOrgFollowersCount(
      ongId: _ong?.id ?? widget.ongId,
      companyId: _corp?.id ?? widget.corpId,
    );
    if (mounted) {
      setState(() => _followersCount = count);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await _followService.unfollowOrg(
          ongId: _ong?.id ?? widget.ongId,
          companyId: _corp?.id ?? widget.corpId,
        );
      } else {
        await _followService.followOrg(
          ongId: _ong?.id ?? widget.ongId,
          companyId: _corp?.id ?? widget.corpId,
        );
      }
      _checkFollowingStatus();
      _loadFollowersCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar solicitação: $e')),
        );
      }
    }
  }

  Future<void> _openEditProfile() async {
    if (_ong != null) {
      final updated = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (_) => EditOngProfileScreen(ong: _ong!),
        ),
      );
      if (updated is OngProfile && mounted) {
        setState(() {
          _ong = updated;
        });
      }
      if (mounted) {
        _loadData();
      }
    } else if (_corp != null) {
      final updated = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (_) => EditCorpProfilePage(corp: _corp!),
        ),
      );
      if (updated is CorpProfile && mounted) {
        setState(() {
          _corp = updated;
        });
      }
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _showChannelUnavailableDialog({
    required String channelType,
    required String channelName,
    required IconData icon,
    required Color iconColor,
    String? customMessage,
  }) {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;
    final orgName = _ong?.name ?? _corp?.name ?? 'esta organização';
    final ongEmail = _ong?.email?.trim();
    final corpEmail = _corp?.email.trim();
    final alternativeEmail = (ongEmail != null && ongEmail.isNotEmpty)
        ? ongEmail
        : ((corpEmail != null && corpEmail.isNotEmpty) ? corpEmail : null);

    String title;
    String description;
    String tip;

    if (customMessage != null) {
      title = 'Informação';
      description = customMessage;
      tip = _isOwner
          ? 'Toque em "Editar Perfil" para manter seus canais de contato atualizados.'
          : 'Você pode acompanhar as novidades e publicações desta organização no Patas.';
    } else if (channelType == 'whatsapp') {
      title = 'WhatsApp indisponível';
      if (_isOwner) {
        description =
            'Você ainda não cadastrou um número de WhatsApp para sua organização.';
        tip =
            'Adicione um WhatsApp para que seus apoiadores e adotantes entrem em contato direto com você.';
      } else {
        description =
            '$orgName ainda não disponibilizou um número de WhatsApp para contato.';
        tip =
            'Você pode deixar um comentário nas publicações da organização para solicitar o número de WhatsApp ou mais informações.';
      }
    } else if (channelType == 'email') {
      title = 'E-mail indisponível';
      if (_isOwner) {
        description =
            'Você ainda não cadastrou um e-mail de contato para o seu perfil.';
        tip = 'Adicione um e-mail para receber contatos institucionais e dúvidas.';
      } else {
        description =
            '$orgName ainda não cadastrou um e-mail público para contato.';
        tip = 'Você pode interagir através dos comentários nas publicações da organização.';
      }
    } else if (channelType == 'site') {
      title = 'Site não cadastrado';
      if (_isOwner) {
        description =
            'Você ainda não cadastrou o site oficial da sua organização.';
        tip = 'Adicione um link para divulgar suas campanhas e iniciativas externas.';
      } else {
        description =
            '$orgName não possui um site ou link institucional cadastrado no momento.';
        tip = 'Fique por dentro das atualizações diretamente pelo feed do Patas.';
      }
    } else {
      title = 'Endereço não cadastrado';
      if (_isOwner) {
        description =
            'Você ainda não cadastrou o endereço físico da sua organização.';
        tip = 'Adicione sua localização para orientar visitantes e doadores.';
      } else {
        description =
            '$orgName atua de forma remota ou ainda não disponibilizou um endereço físico.';
        tip =
            'Consulte as publicações ou outros canais de contato para saber onde encontrar.';
      }
    }

    return showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone com fundo suave circular
              Container(
                width: 62.w,
                height: 62.h,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 30.sp),
                ),
              ),
              SizedBox(height: 16.h),

              // Título
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              SizedBox(height: 8.h),

              // Descrição
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  height: 1.35,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 14.h),

              // Card de Dica
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.3,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Ações
              if (_isOwner) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'Agora não',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14.sp,
                            color:
                                isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _openEditProfile();
                        },
                        icon: Icon(Icons.edit_rounded,
                            size: 16.sp, color: Colors.white),
                        label: Text(
                          'Cadastrar',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (channelType == 'whatsapp' &&
                    alternativeEmail != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _launchEmail(alternativeEmail);
                      },
                      icon: Icon(Icons.mail_outline_rounded,
                          size: 16.sp, color: AppColors.patasColor),
                      label: Text(
                        'Entrar em contato por E-mail',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: AppColors.patasColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patasColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Entendi',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String? url, {String? title}) async {
    if (url == null || url.isEmpty) {
      _showChannelUnavailableDialog(
        channelType: 'site',
        channelName: title ?? 'Site',
        icon: Icons.language_rounded,
        iconColor: AppColors.patasColor,
      );
      return;
    }
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showChannelUnavailableDialog(
        channelType: 'whatsapp',
        channelName: 'WhatsApp',
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF25D366),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/55$cleanPhone';
    _launchUrl(url, title: 'WhatsApp');
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) {
      _showChannelUnavailableDialog(
        channelType: 'email',
        channelName: 'E-mail',
        icon: Icons.mail_outline_rounded,
        iconColor: const Color(0xFF1976D2),
      );
      return;
    }
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o email.')),
        );
      }
    }
  }

  void _copyToClipboard(String? text, String label) {
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado para a área de transferência!')),
    );
  }

  Future<void> _openInMap(String? address) async {
    if (address == null || address.trim().isEmpty) {
      _showChannelUnavailableDialog(
        channelType: 'address',
        channelName: 'Endereço',
        icon: Icons.location_on_outlined,
        iconColor: Colors.orange,
      );
      return;
    }
    final query = Uri.encodeComponent(address.trim());
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    _launchUrl(url, title: 'Google Maps');
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final profile = _ong ?? _corp;

    final name = _ong?.name ?? _corp?.name ?? 'Organização';
    final photoUrl = _ong?.photoUrl ?? _corp?.photoUrl;
    final coverUrl = _ong?.coverUrl ?? _corp?.coverUrl;
    final about = _ong?.about ?? _corp?.about;
    final location = _ong?.address ?? _corp?.address;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(
        context,
        isDark,
        profile,
        name,
        photoUrl,
        coverUrl,
        about,
        location,
      ),
      desktop: _buildDesktopLayout(
        context,
        isDark,
        profile,
        name,
        photoUrl,
        coverUrl,
        about,
        location,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — Layout preservado com padding seguro
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
    BuildContext context,
    bool isDark,
    dynamic profile,
    String name,
    String? photoUrl,
    String? coverUrl,
    String? about,
    String? location,
  ) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
      body: Skeletonizer(
        enabled: !_isDataLoaded,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header unificado com Imagem de Capa e Botão de Voltar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Imagem de Capa
                      SizedBox(
                        height: 240.h,
                        width: 1.sw,
                        child: coverUrl != null && coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.grey.shade300,
                                ),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/image_capa.jpg',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/image_capa.jpg',
                                fit: BoxFit.cover,
                              ),
                      ),
                      // Overlay gradiente na capa
                      Container(
                        height: 240.h,
                        width: 1.sw,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),

                      // Botão de voltar se houver navegação
                      if (Navigator.of(context).canPop())
                        Positioned(
                          top: 16.h,
                          left: 16.w,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 16.sp, color: Colors.white),
                            ),
                          ),
                        ),

                      // Botão de editar capa para o dono
                      if (_isOwner)
                        Positioned(
                          top: 16.h,
                          right: 16.w,
                          child: InkWell(
                            onTap: () async {
                              if (_ong != null) {
                                final updated = await Navigator.push<dynamic>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditOngProfileScreen(ong: _ong!),
                                  ),
                                );
                                if (updated is OngProfile && mounted) {
                                  setState(() {
                                    _ong = updated;
                                  });
                                }
                              } else if (_corp != null) {
                                final updated = await Navigator.push<dynamic>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditCorpProfilePage(corp: _corp!),
                                  ),
                                );
                                if (updated is CorpProfile && mounted) {
                                  setState(() {
                                    _corp = updated;
                                  });
                                }
                              }
                              if (mounted) {
                                _loadData();
                              }
                            },
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      size: 15.sp, color: Colors.white),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Editar Capa',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Avatar posicionado sobre a borda da capa
                      Positioned(
                        bottom: -45.h,
                        left: 16.w,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBG : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52.r,
                            backgroundColor: AppColors.patasColor,
                            child: CircleAvatar(
                              radius: 49.r,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(photoUrl)
                                      : const AssetImage(
                                              'assets/image_placeholder.png')
                                          as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                      // Nome e Localização (ao lado do avatar)
                      Positioned(
                        bottom: -40.h,
                        left: 135.w,
                        child: SizedBox(
                          width: 1.sw - 150.w, // Garante que não transborde
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : AppColors.darkBG,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (location != null && location.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                InkWell(
                                  onTap: () => _openInMap(location),
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 13.sp,
                                          color: AppColors.patasColor),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationStyle:
                                                TextDecorationStyle.dotted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Espaço para compensar o avatar que está "sob" a borda
                  SizedBox(height: 55.h),

                  // Linha de Estatísticas
                  _buildStatsRow(isDark),

                  // Botões de Ação
                  _buildActionButtons(isDark, profile),

                  // Sobre
                  if (about != null && about.isNotEmpty)
                    _buildSectionHeader('Sobre', isDark, about),

                  // Endereço e Localização Completa
                  if (location != null && location.isNotEmpty) ...[
                    _buildLocationCard(isDark, location),
                    SizedBox(height: 14.h),
                  ],

                  // Detalhes Específicos
                  if (_ong != null)
                    _buildOngDetails(isDark, _ong!)
                  else if (_corp != null)
                    _buildCorpDetails(isDark, _corp!),

                  SizedBox(height: 20.h),

                  // Publicações
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded,
                            size: 20.sp, color: AppColors.patasColor),
                        SizedBox(width: 8.w),
                        Text(
                          'Publicações',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  FutureBuilder<List<Post>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !_isDataLoaded) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                              color: AppColors.patasColor),
                        ));
                      }
                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty && _isDataLoaded) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.w),
                            child: Column(
                              children: [
                                Icon(Icons.post_add_rounded,
                                    size: 50.sp,
                                    color: Colors.grey.withValues(alpha: 0.5)),
                                SizedBox(height: 10.h),
                                Text(
                                  'Nenhuma publicação ainda.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return PublishWidget(
                        posts: posts,
                        isLoading: !_isDataLoaded,
                        onActionComplete: _loadPosts,
                      );
                    },
                  ),
                  const MobileScrollPadding(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Layout em 2 colunas proporcional aos padrões oficiais do Patas
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    dynamic profile,
    String name,
    String? photoUrl,
    String? coverUrl,
    String? about,
    String? location,
  ) {
    final bgColor = isDark ? AppColors.bodygray : const Color(0xffF5F5F5);
    final cardBg = isDark ? const Color(0xff1e1e1e) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : AppColors.darkBG;

    return Scaffold(
      backgroundColor: bgColor,
      body: Skeletonizer(
        enabled: !_isDataLoaded,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.patasColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card de cabeçalho do perfil desktop ─────────────
                      _buildDesktopProfileHeader(
                        context,
                        isDark,
                        profile,
                        name,
                        photoUrl,
                        coverUrl,
                        location,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Layout de 2 colunas: detalhes laterais + publicações ───
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coluna Lateral (300px)
                          SizedBox(
                            width: 300,
                            child: Column(
                              children: [
                                // Card Sobre (se preenchido)
                                if (about != null && about.isNotEmpty) ...[
                                  _buildDesktopCard(
                                    title: 'Sobre',
                                    icon: Icons.info_outline_rounded,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    isDark: isDark,
                                    child: Text(
                                      about,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Card de Detalhes da ONG
                                if (_ong != null) ...[
                                  _buildDesktopCard(
                                    title: 'Causa & Apoiadores',
                                    icon: Icons.volunteer_activism_rounded,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    isDark: isDark,
                                    child: _buildDesktopOngDetails(isDark, _ong!),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Card de Detalhes da Empresa
                                if (_corp != null) ...[
                                  _buildDesktopCard(
                                    title: 'Detalhes Comerciais',
                                    icon: Icons.storefront_rounded,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    isDark: isDark,
                                    child:
                                        _buildDesktopCorpDetails(isDark, _corp!),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Card Canais de Contato
                                _buildDesktopCard(
                                  title: 'Canais de Contato',
                                  icon: Icons.connect_without_contact_rounded,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  child: _buildDesktopContactChannels(
                                      isDark, profile),
                                ),
                                const SizedBox(height: 16),

                                // Card Localização / Endereço
                                if (location != null &&
                                    location.isNotEmpty) ...[
                                  _buildDesktopCard(
                                    title: 'Localização',
                                    icon: Icons.location_on_rounded,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    isDark: isDark,
                                    child: _buildDesktopLocationContent(
                                        isDark, location),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Coluna Principal Direita (Publicações)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDesktopCard(
                                  title: 'Publicações',
                                  icon: Icons.grid_view_rounded,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  child: FutureBuilder<List<Post>>(
                                    future: _postsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          !_isDataLoaded) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(
                                              color: AppColors.patasColor,
                                            ),
                                          ),
                                        );
                                      }
                                      final posts = snapshot.data ?? [];
                                      if (posts.isEmpty && _isDataLoaded) {
                                        return Center(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.all(40.0),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.post_add_rounded,
                                                  size: 48,
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  'Nenhuma publicação ainda.',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return PublishWidget(
                                        posts: posts,
                                        isLoading: !_isDataLoaded,
                                        onActionComplete: _loadPosts,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header de perfil desktop ─────────────────────────────────────────────
  Widget _buildDesktopProfileHeader(
    BuildContext context,
    bool isDark,
    dynamic profile,
    String name,
    String? photoUrl,
    String? coverUrl,
    String? location, {
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Faixa de capa (220px)
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: hasCover
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade300,
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/image_capa.jpg',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/image_capa.jpg',
                        fit: BoxFit.cover,
                      ),
              ),
              // Botão de voltar se houver navegação
              if (Navigator.of(context).canPop())
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              // Botão de editar capa para o dono
              if (_isOwner)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      tooltip: 'Editar foto de capa',
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () async {
                        if (_ong != null) {
                          final updated = await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditOngProfileScreen(ong: _ong!),
                            ),
                          );
                          if (updated is OngProfile && mounted) {
                            setState(() {
                              _ong = updated;
                            });
                          }
                        } else if (_corp != null) {
                          final updated = await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditCorpProfilePage(corp: _corp!),
                            ),
                          );
                          if (updated is CorpProfile && mounted) {
                            setState(() {
                              _corp = updated;
                            });
                          }
                        }
                        if (mounted) {
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),

          // Informações abaixo da capa
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar sobrepondo a capa
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.patasColor,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: hasPhoto
                            ? CachedNetworkImageProvider(photoUrl)
                            : const AssetImage('assets/image_placeholder.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Nome, categoria/subtítulo, localização e estatísticas
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Nome + Subtítulo/Localização
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Fredoka',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              if (_ong != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.volunteer_activism_rounded,
                                        size: 14, color: AppColors.patasColor),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'ONG • Proteção Animal',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              else if (_corp != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront_rounded,
                                        size: 14, color: AppColors.patasColor),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Empresa • ${_corp!.category}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (location != null && location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _openInMap(location),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_rounded,
                                          size: 14, color: AppColors.patasColor),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          location,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationStyle:
                                                TextDecorationStyle.dotted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Estatísticas + Ação (Wrap fluido para nunca dar overflow horizontal)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDesktopStatItem('---', 'Posts', isDark,
                                  isPostsCount: true),
                              const SizedBox(width: 16),
                              _buildDesktopStatItem(
                                  '$_followersCount', 'Seguidores', isDark),
                              const SizedBox(width: 16),
                              _buildDesktopStatItem('0', 'Seguindo', isDark),
                            ],
                          ),
                          if (_isOwner)
                            ElevatedButton.icon(
                              onPressed: _openEditProfile,
                              icon: const Icon(
                                  Icons.mode_edit_outline_rounded,
                                  size: 16,
                                  color: Colors.white),
                              label: const Text(
                                'Editar Perfil',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.patasColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.transparent
                                    : AppColors.patasColor,
                                foregroundColor: _isFollowing
                                    ? AppColors.patasColor
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: _isFollowing
                                      ? const BorderSide(
                                          color: AppColors.patasColor)
                                      : BorderSide.none,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isFollowing ? 'Seguindo' : 'Seguir',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isFollowing
                                      ? AppColors.patasColor
                                      : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Componentes de apoio desktop ──────────────────────────────────────────
  Widget _buildDesktopCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.patasColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatItem(
    String countLabel,
    String label,
    bool isDark, {
    bool isPostsCount = false,
  }) {
    if (isPostsCount && _isDataLoaded) {
      return FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _desktopStatColumn('$count', label, isDark);
        },
      );
    }
    return _desktopStatColumn(countLabel, label, isDark);
  }

  Widget _desktopStatColumn(String count, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopOngDetails(bool isDark, OngProfile ong) {
    final hasPix = ong.donationPix != null && ong.donationPix!.isNotEmpty;
    final hasAnimals = ong.animalsUnderCare != null;
    final hasAreas = ong.activityAreas != null && ong.activityAreas!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPix) ...[
          InkWell(
            onTap: () => _copyToClipboard(ong.donationPix, 'Chave PIX'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.patasColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded,
                      size: 22, color: AppColors.patasColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chave PIX para doação',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ong.donationPix!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 16, color: AppColors.patasColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (hasAnimals) ...[
          Row(
            children: [
              const Icon(Icons.pets_rounded,
                  size: 18, color: AppColors.patasColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Animais sob cuidado:',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              Text(
                '${ong.animalsUnderCare}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (hasAreas) ...[
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded,
                  size: 18, color: AppColors.patasColor),
              const SizedBox(width: 8),
              Text(
                'Áreas de Atuação',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ong.activityAreas!
                .map((area) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300),
                      ),
                      child: Text(
                        area,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopCorpDetails(bool isDark, CorpProfile corp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDesktopDetailRow(
            Icons.category_rounded, 'Categoria', corp.category, isDark),
        if (corp.openingHours != null && corp.openingHours!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildDesktopDetailRow(Icons.access_time_filled_rounded, 'Horário',
              corp.openingHours!, isDark),
        ],
        if (corp.workingDays != null && corp.workingDays!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildDesktopDetailRow(Icons.calendar_month_rounded,
              'Dias de Atendimento', corp.workingDays!, isDark),
        ],
      ],
    );
  }

  Widget _buildDesktopDetailRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.patasColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContactChannels(bool isDark, dynamic profile) {
    final phone = profile?.phone as String?;
    final email = profile?.email as String?;
    final website = profile?.website as String?;

    return Column(
      children: [
        _buildDesktopContactTile(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: const Color(0xFF25D366),
          title: 'WhatsApp',
          value: phone != null && phone.isNotEmpty ? phone : 'Não informado',
          onTap: () => _launchWhatsApp(phone),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildDesktopContactTile(
          icon: Icons.mail_outline_rounded,
          iconColor: const Color(0xFF1976D2),
          title: 'E-mail',
          value: email != null && email.isNotEmpty ? email : 'Não informado',
          onTap: () => _launchEmail(email),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildDesktopContactTile(
          icon: Icons.language_rounded,
          iconColor: AppColors.patasColor,
          title: 'Site Oficial',
          value:
              website != null && website.isNotEmpty ? website : 'Não informado',
          onTap: () => _launchUrl(website),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDesktopContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLocationContent(bool isDark, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          location,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openInMap(location),
                icon: const Icon(Icons.map_rounded,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Ver no Maps',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(location, 'Endereço'),
              icon: const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.patasColor),
              label: Text(
                'Copiar',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('---', 'Postagens', isDark),
          _buildStatItem('$_followersCount', 'Seguidores', isDark),
          _buildStatItem('0', 'Seguindo', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String countLabel, String label, bool isDark) {
    if (label == 'Postagens' && _isDataLoaded) {
      return FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _statColumn('$count', label, isDark);
        },
      );
    }
    return _statColumn(countLabel, label, isDark);
  }

  Widget _statColumn(String count, String label, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, dynamic profile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      child: Column(
        children: [
          if (_isOwner) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openEditProfile,
                icon: Icon(Icons.mode_edit_outline_rounded,
                    size: 18.sp, color: Colors.white),
                label: Text(
                  'Editar Perfil',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isFollowing ? Colors.transparent : AppColors.patasColor,
                  foregroundColor:
                      _isFollowing ? AppColors.patasColor : Colors.white,
                  minimumSize: Size(double.infinity, 45.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: _isFollowing
                        ? const BorderSide(color: AppColors.patasColor)
                        : BorderSide.none,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isFollowing ? 'Seguindo' : 'Seguir',
                  style: TextStyle(
                      fontSize: 16.sp,
                      color: _isFollowing ? AppColors.patasColor : Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildContactButton(Icons.phone_rounded, 'WhatsApp',
                  () => _launchWhatsApp(profile.phone)),
              SizedBox(width: 10.w),
              _buildContactButton(Icons.mail_rounded, 'E-mail',
                  () => _launchEmail(profile.email)),
              SizedBox(width: 10.w),
              _buildContactButton(Icons.language_rounded, 'Site',
                  () => _launchUrl(profile.website)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = Provider.of<DarkMode>(context, listen: false).darkMode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.patasColor),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, String content) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngDetails(bool isDark, OngProfile ong) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (ong.donationPix != null && ong.donationPix!.isNotEmpty)
            _buildInfoRow(
                Icons.qr_code_rounded, 'Chave PIX', ong.donationPix!, isDark,
                onTap: () => _copyToClipboard(ong.donationPix, 'PIX')),
          if (ong.animalsUnderCare != null)
            _buildInfoRow(Icons.pets_rounded, 'Animais sob cuidado',
                '${ong.animalsUnderCare}', isDark),
          if (ong.activityAreas != null && ong.activityAreas!.isNotEmpty)
            _buildChipsRow(Icons.volunteer_activism_rounded, 'Atuação',
                ong.activityAreas!, isDark),
        ],
      ),
    );
  }

  Widget _buildCorpDetails(bool isDark, CorpProfile corp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
              Icons.category_rounded, 'Categoria', corp.category, isDark),
          if (corp.openingHours != null)
            _buildInfoRow(Icons.access_time_filled_rounded, 'Horário',
                corp.openingHours!, isDark),
          if (corp.workingDays != null)
            _buildInfoRow(Icons.calendar_month_rounded, 'Dias',
                corp.workingDays!, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark,
      {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColors.patasColor),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : AppColors.darkBG,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const Spacer(),
              Icon(Icons.copy_rounded, size: 16.sp, color: Colors.grey),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChipsRow(
      IconData icon, String label, List<String> chips, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.patasColor),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: chips
                .map((chip) => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: AppColors.patasColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDark, String location) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.green.shade50.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 20.sp, color: AppColors.patasColor),
              SizedBox(width: 8.w),
              Text(
                'Endereço & Localização',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SelectableText(
            location,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInMap(location),
                  icon:
                      Icon(Icons.map_rounded, size: 16.sp, color: Colors.white),
                  label: Text(
                    'Ver no Google Maps',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(location, 'Endereço'),
                icon: Icon(Icons.copy_rounded,
                    size: 15.sp, color: AppColors.patasColor),
                label: Text(
                  'Copiar',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
