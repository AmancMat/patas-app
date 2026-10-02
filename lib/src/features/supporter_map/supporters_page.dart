import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';

class SupportersPage extends StatefulWidget {
  const SupportersPage({super.key});

  @override
  State<SupportersPage> createState() => _SupportersPageState();
}

class _SupportersPageState extends State<SupportersPage> {
  final names = [
    'Pedro Gonçalves',
    'Stefanie Mendonça',
    'Thiago Tavares',
    'Água Fontes',
    'Elias Favaro',
    'Empório Minas',
    'Rita Silva',
    'Fernanda Monteiro',
    'Artur Martins',
    'Elisabe Matará',
    'Leila Fontall',
    'Zapp',
    'Flora',
    'Bernardo Loops',
    'Rafaela Noronha',
    'Matilda Lora',
    'Mario Lopes',
    'Luna',
    'Mimo',
    'Ester Oliveira',
    'Congorra',
    'Helena Campos',
    'Sandro Sanches',
    'João Alencar',
    'Luz Luna',
    'André Aguiar',
    'Laura Dias',
    'Alex Fontes',
    'Guta Joviar',
    'Apolo Gullar'
  ];

  final photo = [
    'assets/supporters/pedrog.jpg',
    'assets/supporters/stef.jpg',
    'assets/supporters/thi.jpg',
    'assets/supporters/agua.jpg',
    'assets/supporters/elias.jpg',
    'assets/supporters/minas.jpg',
    'assets/supporters/rita.jpg',
    'assets/supporters/fer.jpg',
    'assets/supporters/artur.jpg',
    'assets/supporters/elisa.jpg',
    'assets/supporters/leila.jpg',
    'assets/supporters/zapp.jpg',
    'assets/supporters/flora.jpg',
    'assets/supporters/ber.jpg',
    'assets/supporters/rafa.jpg',
    'assets/supporters/matilda.jpg',
    'assets/supporters/mario.jpg',
    'assets/supporters/luna.jpg',
    'assets/supporters/mimo.jpg',
    'assets/supporters/ester.jpg',
    'assets/supporters/congorra.jpg',
    'assets/supporters/helena.jpg',
    'assets/supporters/sandro.jpg',
    'assets/supporters/joao.jpg',
    'assets/supporters/luz.jpg',
    'assets/supporters/andre.jpg',
    'assets/supporters/guta.jpg',
    'assets/supporters/alex.jpg',
    'assets/supporters/elisa.jpg',
    'assets/supporters/apolo.jpg'
  ];

  final descriptions = [
    'Trabalha como engenheiro civil em uma construtora renomada. É responsável por projetar e fiscalizar obras de infraestrutura urbana e rural. Gosta de viajar, ler e jogar xadrez nas horas vagas.',
    'Advogada especializada em direito ambiental. Defende causas relacionadas à preservação da natureza e dos recursos naturais. É apaixonada por animais e plantas.',
    'Médico cardiologista que cuida da saúde do coração. Tem uma clínica particular e também atende em um hospital público. É casado e tem dois filhos.',
    'Empresa de distribuição de água mineral. Oferece produtos de qualidade e entrega rápida. Tem uma variedade de embalagens e tamanhos para atender às necessidades dos clientes.',
    'Professor de matemática que leciona em uma escola estadual. É mestre em álgebra e geometria. Adora resolver problemas e desafios lógicos.',
    'Empresa de produtos típicos de Minas Gerais. Vende queijos, doces, pães, cachaças e artesanatos. Tem uma loja física e também um site de vendas online.',
    'Jornalista que trabalha em uma revista feminina. Escreve sobre moda, beleza, saúde e comportamento. Está sempre antenada nas últimas tendências e novidades do mercado.',
    'Psicóloga que atende em um consultório particular. Ajuda as pessoas a lidarem com seus problemas emocionais e mentais. Tem uma abordagem humanista e acolhedora.',
    'Músico que toca violão e canta em bares e restaurantes. Compõe suas próprias canções e também faz covers de artistas famosos. Tem um estilo pop rock e uma voz marcante.',
    'Arquiteta que trabalha em um escritório de design. Cria projetos de ambientes residenciais e comerciais. Tem um estilo moderno e sofisticado.',
    'Fotógrafa que registra momentos especiais. Faz ensaios de casamento, aniversário, gestante, infantil e pet. Tem um olhar sensível e criativo.',
    'Empresa de tecnologia que oferece soluções em aplicativos, jogos, inteligência artificial e realidade virtual. Tem uma equipe jovem e inovadora que busca sempre superar as expectativas dos clientes.',
    'Empresa de cosméticos naturais que utiliza ingredientes orgânicos e sustentáveis em seus produtos. Tem uma linha de maquiagem, perfumaria, cuidados com a pele e cabelo. Valoriza a beleza natural e a responsabilidade ambiental.',
    'DJ que anima festas e eventos. Toca diversos gêneros musicais, como eletrônica, funk, hip hop',
    'Dentista que cuida da saúde bucal das pessoas. Faz tratamentos estéticos, como clareamento, implante e aparelho. Tem um consultório moderno e confortável.',
    'Escritora que publica livros de romance. Cria histórias envolventes, com personagens carismáticos e cenários encantadores. Já vendeu mais de um milhão de exemplares no Brasil e no exterior.',
    'Chef de cozinha que comanda um restaurante italiano. Prepara pratos deliciosos, como massas, pizzas, risotos e saladas. Tem um paladar refinado e uma apresentação impecável.',
    'Empresa de moda que vende roupas, acessórios, calçados e joias inspiradas nas fases da lua. Tem peças exclusivas, feitas com tecidos nobres e pedras preciosas. Atrai clientes que buscam elegância e originalidade.',
    'Empresa de presentes personalizados que cria cestas, kits, cartões e lembrancinhas para diversas ocasiões. Tem opções para aniversário, dia dos namorados, dia das mães, dia dos pais, natal etc. Surpreende os clientes com criatividade e carinho.',
    'Estudante de engenharia química que sonha em trabalhar em uma grande indústria. É fascinada por ciência e tecnologia. Participa de projetos de pesquisa e inovação na universidade.',
    'Empresa de transporte coletivo que opera em várias cidades do Brasil. Oferece ônibus confortáveis, seguros e pontuais. Tem uma frota moderna e uma equipe qualificada.',
    'Professora de inglês que ensina em uma escola de idiomas. É fluente na língua e tem experiência no exterior. Utiliza métodos dinâmicos e divertidos para motivar os alunos.',
    'Ator que participa de novelas, filmes e peças de teatro. É talentoso, carismático e versátil. Faz sucesso com o público e a crítica.',
    'Designer gráfico que trabalha em uma agência de publicidade. Cria logos, banners, cartazes, folders e outros materiais gráficos. Tem um senso estético apurado e um domínio das ferramentas digitais.',
    'Empresa de iluminação que fornece produtos e serviços para diversos tipos de eventos. Tem lâmpadas, refletores, holofotes, lasers e outros equipamentos de alta qualidade. Tem uma equipe técnica especializada e criativa.',
    'Advogado criminalista que defende os direitos dos seus clientes. É experiente, competente e ético. Atua em casos complexos e polêmicos.',
    'Modelo que desfila para marcas famosas de moda. É bonita, elegante e fotogênica. Tem um corpo escultural e um rosto expressivo.',
    'Trabalha como engenheiro civil em uma construtora renomada. É responsável por projetar e fiscalizar obras de infraestrutura urbana e rural. Gosta de viajar, ler e jogar xadrez nas horas vagas.',
    'Advogada especializada em direito ambiental. Defende causas relacionadas à preservação da natureza e dos recursos naturais. É apaixonada por animais e plantas.',
    'Poeta que escreve versos inspirados na vida cotidiana. É sensível, criativo e original. Publica seus poemas em livros, revistas e redes sociais.'
  ];

  final insta = [
    '@PedroG',
    '@Stefanie_Mend',
    '@Thi_Tavares',
    '@Água-Fontes',
    '@Elias.Favaro',
    '@Empório_Minas',
    '@R_Silva',
    '@Fernanda-Mont',
    '@Artur_Martins',
    '@Elisab.Matará',
    '@Leila00Fontall',
    '@Zapp',
    '@FloraOficial',
    '@Bernardo_Loops',
    '@Rafa&Noronha',
    '@Matilda.Lora',
    '@Mario00L',
    '@Luna01',
    '@Mimo0067',
    '@Ester_Olive',
    '@Congorra',
    '@H-Campos',
    '@Sandro.Sanches',
    '@João-Alencar',
    '@Luz&Luna',
    '@AndrAguiar',
    '@Laura..Dias',
    '@Alex--Fontes',
    '@GutaJoviar',
    '@Apolo-.Gullar'
  ];

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final double itemHeight = (1.sh - kToolbarHeight - 1) / 2.60;
    final double itemWidth = 1.sw / 2;
    return Scaffold(
        backgroundColor:
            thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
        appBar: AppBar(
          backgroundColor:
              thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.patasColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Nossos Apoiadores',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: thmode.darkMode ? Colors.white : AppColors.darkBG,
            ),
          ),
          centerTitle: true,
        ),
        body: PhotoView.customChild(
          backgroundDecoration: const BoxDecoration(color: Colors.white),
          minScale: PhotoViewComputedScale.contained * 2,
          maxScale: PhotoViewComputedScale.covered * 4,
          initialScale: PhotoViewComputedScale.covered * 6.0,
          basePosition: Alignment.topLeft,
          childSize: Size(1.sw, 1.sh),
          child: Container(
            color: thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
            child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 10.h),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: (itemWidth / itemHeight),
                    crossAxisCount: 6),
                itemCount: names.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppColors.patasGradient,
                        ),
                      ),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 150.h,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.asset(
                                photo[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(4.r),
                            child: Text(
                              names[index],
                              style: TextStyle(
                                  fontSize: 4.sp,
                                  color: AppColors.patasColor,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 60,
                                  child: Container(
                                    height: 77.h,
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    color: Colors.blueGrey,
                                    width: double.infinity,
                                    padding:
                                        EdgeInsets.only(left: 2.w, right: 2.w),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Seguir no Insta',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 2.sp,
                                          ),
                                        ),
                                        Text(
                                          insta[index],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 3.5.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Container(
                                    height: 30.h,
                                    width: double.infinity,
                                    padding: EdgeInsets.all(2.r),
                                    decoration: BoxDecoration(
                                        color: AppColors.patasColor,
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(8.r),
                                            bottomRight: Radius.circular(8.r))),
                                    child: Center(
                                      child: Text(
                                        descriptions[index],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 2.5.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ));
  }
}
