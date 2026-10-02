/// Utilitário para determinar o ícone correto do Patas Saúde
/// de acordo com a espécie do animal ativo.
class HealthIconHelper {
  /// Retorna o caminho do asset SVG outline para a espécie.
  /// Na BottomNavigationBar e Sidebar do Patas, todos os ícones permanecem
  /// sempre em outline, alternando exclusivamente a cor (ativo = laranja, inativo = branco/cinza).
  static String getHealthIconPath({
    required String? species,
    bool? isActive,
  }) {
    final sp = species?.toLowerCase().trim() ?? '';

    if (sp == 'felino' || sp == 'gato' || sp == 'felinos' || sp == 'gatos') {
      return 'assets/icons/patas_saude_felino_out.svg';
    } else if (sp == 'ave' || sp == 'aves' || sp == 'passaro' || sp == 'pássaro' || sp == 'passaros' || sp == 'pássaros') {
      return 'assets/icons/patas_saude_ave_out.svg';
    } else if (sp == 'roedor' || sp == 'roedores' || sp == 'hamster' || sp == 'coelho' || sp == 'coelhos') {
      return 'assets/icons/patas_saude_roedor_out.svg';
    } else if (sp == 'exotico' || sp == 'exótico' || sp == 'exoticos' || sp == 'exóticos' || sp == 'reptil' || sp == 'réptil' || sp == 'repteis' || sp == 'répteis') {
      return 'assets/icons/patas_saude_exotico_out.svg';
    } else if (sp == 'canino' || sp == 'caninos' || sp == 'cao' || sp == 'cão' || sp == 'caes' || sp == 'cães' || sp == 'cachorro' || sp == 'cachorros') {
      return 'assets/icons/patas_saude_canino_out.svg';
    }

    // Fallback padrão se não houver espécie definida ou pet ativo
    return 'assets/icons/patas_saude_canino_out.svg';
  }
}
