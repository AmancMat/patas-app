import 'package:flutter/material.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app.dart';

class TextoDicasPage extends StatelessWidget {
  final VoidCallback? onBack;
  const TextoDicasPage({super.key, this.onBack});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Biblioteca de Artigos',
        subtitle: 'Guias e conteúdos veterinários verificados para a saúde do seu pet',
        onBack: onBack,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _buildBlogCard(
                context,
                title: 'Alimentos Proibidos: O que cães não podem comer',
                blogName: 'Blog Cobasi • Alimentação',
                content: '''Uma dieta balanceada e adequada é a base para a longevidade e saúde do seu pet. O organismo canino processa os alimentos de forma muito diferente do nosso, tornando ingredientes cotidianos altamente tóxicos.

Principais vilões na alimentação dos cães:
• Chocolate: Contém teobromina, substância que cães não metabolizam. Pode causar vômitos, convulsões e taquicardia severa.
• Cebola e Alho: Contêm tiossulfato, que destrói os glóbulos vermelhos provocando anemia hemolítica grave.
• Uvas e Passas: Extremamente nefrotóxicas, mesmo em pequenas porções podem causar falência renal aguda.
• Xilitol: Adoçante presente em doces diet, pasta de dente e gomas de mascar; causa rápida hipoglicemia e lesão hepática.

Caso ocorra ingestão acidental de algum alimento perigoso, nunca induza o vômito por conta própria e procure atendimento veterinário imediatamente.''',
                url: 'https://blog.cobasi.com.br/o-que-cachorro-nao-pode-comer/',
                imageUrl: 'https://cobasiblog.blob.core.windows.net/production-ofc/2019/12/o-que-cachorro-nao-pode-comer-capa.webp',
                isDark: isDark,
              ),
              _buildBlogCard(
                context,
                title: 'Como Adestrar Cachorro em Casa: Dicas e Tutoriais',
                blogName: 'Blog Cobasi • Comportamento',
                content: '''O adestramento positivo baseia-se na ciência comportamental: comportamentos que geram recompensas tendem a se repetir, enquanto comportamentos ignorados são gradualmente extintos.

Passo a passo para treinar em casa:
• Sessões curtas: Faça treinos diários de 5 a 15 minutos para manter o foco e evitar cansaço mental do pet.
• Comandos básicos: Comece ensinando "senta", "fica" e "junto", recompensando imediatamente no momento exato do acerto.
• Reforço positivo: Utilize petiscos de alto valor e elogios entusiasmados. Nunca utilize agressão física ou gritos, pois geram medo e bloqueio cognitivo.
• Paciência e consistência: Todos na casa devem usar as mesmas palavras de comando para não confundir o cão.''',
                url: 'https://blog.cobasi.com.br/como-adestrar-um-cachorro/',
                imageUrl: 'https://cobasiblog.blob.core.windows.net/production-ofc/2023/06/31A7860_1CG.webp',
                isDark: isDark,
              ),
              _buildBlogCard(
                context,
                title: 'Vacina V10 Canina: Para que serve e quando aplicar',
                blogName: 'Blog Cobasi • Saúde & Prevenção',
                content: '''A vacina múltipla (V10 ou V8) é um dos cuidados mais fundamentais na medicina preventiva veterinária, garantindo imunidade contra vírus altamente letais.

Doenças prevenidas pela V10:
• Cinomose canina (vírus com alto índice de mortalidade).
• Parvovirose (causadora de gastroenterite hemorrágica severa).
• Coronavirose e Hepatite Infecciosa canina.
• Adenovirose tipo 2 e Parainfluenza.
• 4 sorovares de Leptospirose (bactéria transmitida por urina de roedores).

Calendário de aplicação:
Filhotes devem iniciar entre 45 e 60 dias de vida com 3 a 4 doses com intervalo de 21 a 30 dias. Cães adultos necessitam de dose de reforço anual obrigatória.''',
                url: 'https://blog.cobasi.com.br/vacina-v10/',
                imageUrl: 'https://cobasiblog.blob.core.windows.net/production-ofc/2021/02/Vacina-v10-capa.png',
                isDark: isDark,
              ),
              _buildBlogCard(
                context,
                title: 'Tártaro em Cachorro: Cuidados com a Saúde Bucal',
                blogName: 'Blog Cobasi • Saúde Bucal',
                content: '''O famoso "bafinho" do pet não é normal: o mau hálito persistente quase sempre indica acúmulo de placa bacteriana e cálculo dental (tártaro).

Riscos para o organismo do pet:
As bactérias alojadas na gengiva inflamada (gengivite) podem penetrar na corrente sanguínea e atingir órgãos vitais, provocando endocardite bacteriana no coração e insuficiência renal crônica.

Como prevenir e tratar:
• Escovação regular com pasta de dente de uso exclusivo veterinário (pastas humanas contêm flúor tóxico para cães).
• Brinquedos mastigáveis de nylon e petiscos antitártaro ajudam na limpeza mecânica.
• Se houver placas endurecidas amarelas ou amarronzadas, agende uma avaliação para profilaxia dentária (limpeza ultrassônica) com médico-veterinário.''',
                url: 'https://blog.cobasi.com.br/tartaro-em-cachorro/',
                imageUrl: 'https://cobasiblog.blob.core.windows.net/production-ofc/2020/01/tartaro-em-cachorro-capa.png',
                isDark: isDark,
              ),
              _buildBlogCard(
                context,
                title: 'Como Cuidar de um Filhote de Cachorro em Casa',
                blogName: 'Blog Cobasi • Filhotes',
                content: '''A chegada de um filhote é um momento mágico que exige preparação cuidadosa do ambiente para garantir segurança e conforto.

Checklist dos primeiros dias:
• Espaço aconchegante: Providencie caminha macia, cobertor e um local aquecido longe de correntes de ar.
• Alimentação premium para filhotes: Forneça a quantidade recomendada fracionada em 3 a 4 refeições diárias.
• Local das necessidades: Delimite desde o primeiro dia o tapete higiênico distante do comedouro e bebedouro.
• Segurança preventiva: Recolha fios elétricos expostos, produtos químicos e plantas tóxicas do alcance do novo morador.
• Quarentena inicial: Mantenha o filhote dentro de casa até que o ciclo completo de vacinação e vermifugação esteja concluído.''',
                url: 'https://blog.cobasi.com.br/filhote-de-cachorro/',
                imageUrl: 'https://blog.cobasi.com.br/wp-content/uploads/2020/11/filhote-capa.png',
                isDark: isDark,
              ),
              _buildBlogCard(
                context,
                title: 'Como Acabar com Pulgas no Cachorro e no Ambiente',
                blogName: 'Blog Cobasi • Controle de Pragas',
                content: '''Você sabia que apenas 5% das pulgas e carrapatos estão no corpo do animal? Os outros 95% estão em forma de ovos, larvas e casulos espalhados pela casa, frestas de piso, sofás e caminhas.

Protocolo duplo de combate:
• No pet: Administre antiparasitários modernos prescritos pelo veterinário (comprimidos mastigáveis, coleiras de longa duração ou pipetas pour-on). Respeite sempre os prazos de reaplicação da bula.
• No ambiente: Aspire tapetes e frestas de rodapés frequentemente e lave caminhas e cobertores com água quente. Utilize desinfetantes ambientais de uso veterinário específicos para controle de parasitas.
• Evite receitas caseiras como vinagre ou desinfetantes humanos, que podem irritar e intoxicar o animal.''',
                url: 'https://blog.cobasi.com.br/como-acabar-com-pulgas/',
                imageUrl: 'https://cobasiblog.blob.core.windows.net/production-ofc/2020/12/como-acabar-com-pulgas-capa-alt.webp',
                isDark: isDark,
              ),
              const MobileScrollPadding(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard(
    BuildContext context, {
    required String title,
    required String blogName,
    required String content,
    required String url,
    required String imageUrl,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.darkBG : AppColors.bodyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        iconColor: AppColors.patasColor,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 50,
              color: AppColors.patasColor.withValues(alpha: 0.15),
              child: const Icon(
                Icons.article_rounded,
                color: AppColors.patasColor,
                size: 26,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: isDark ? Colors.white : AppColors.darkBG,
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            blogName,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              color: AppColors.patasColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(url),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'Ler Artigo Completo no Blog Cobasi',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

