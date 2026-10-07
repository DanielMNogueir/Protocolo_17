# Distrito integrado — 07/10/2026

O mesmo cuidado de composição do laboratório foi aplicado aos quatro setores da campanha, mantendo o reservatório abandonado como ambiente: concreto frio, ferragens escuras, detalhes de bronze, água em circulação e vegetação nas juntas úmidas.

## Organização por função

- **Cais de captação:** conjunto de tanques, clarificador e bomba com circuito de serviço; carga agrupada no cais e gabinete de vazão junto ao canal de retenção.
- **Pátio de energia:** painéis solares alimentam a instalação existente; gabinete de serviço junto à bomba, materiais de manutenção na área técnica e passarela atravessando o canal lateral.
- **Filtragem:** pares de filtros ligados por tubulação, medidor de vazão antes do conjunto, área de insumos e tanque de retenção com bordas construídas.
- **Distribuição:** equipamento de tratamento e manifold conectados à rede; controle de serviço, reservatório delimitado e estoque de reserva ao sul.

Os oito espaços de serviço recebem acabamento e identificação discreta no piso. Tubos e condutos desenhados no chão são instalações embutidas e podem ser atravessados. Equipamentos e paredes possuem bases físicas próprias.

## Piso, margens e pontes

O concreto usa uma amostra contínua por setor, em vez de recortes aleatórios por ladrilho. Juntas, pequenas fissuras, umidade e musgo ligado às raízes permanecem registrados nas coordenadas do mundo. A cobertura vegetal foi reduzida no pátio e mantida nas margens, vazamentos e áreas de retenção.

Muros de contenção acompanham as bordas externas, os dezesseis canais e os dois reservatórios retangulares. As aberturas são calculadas a partir das pontes, passarelas e conexões hidráulicas reais. A borda baixa bloqueia os pés; os pulsos passam por cima, como já ocorre nos canais abertos. O clarificador circular usa sua própria estrutura.

Pontes e passarelas recebem material de grade, juntas metálicas, soleiras, parafusos e marcações de segurança. Os corredores de circulação e as travas de progressão conservam suas dimensões. Guarda-corpos e pilares continuam ordenados pela altura da base, como os equipamentos e personagens.

## Sombras e efeitos

`district_lighting.gd` constrói uma máscara estática de contato e projeção usando as bases reais de equipamentos, paredes e pontes. A máscara tem 640 × 450 pixels, quatro pixels de mundo por amostra; a umidade é calculada em resolução menor e interpolada antes de registrar as sombras. A altura visual determina a extensão da projeção, com direção de luz comum.

`district_lighting.gdshader` suaviza as projeções e acrescenta brilho discreto nas margens úmidas e iluminação de serviço âmbar/ciano conforme cada sistema é restaurado. A superfície composta de 1280 × 900 permanece nas coordenadas do mapa, é desenhada acima do chão/água e abaixo dos objetos, e não afeta a interface. Sua atualização é desativada no menu e no prólogo.

As projeções de arquitetura são estáticas. Personagens e inimigos conservam suas sombras de contato existentes; não foram implementadas sombras dinâmicas projetadas para eles. Os efeitos hidráulicos e shaders de água anteriores continuam ativos.

## Validação reproduzível

- `tests/test_district_architecture.gd`: bases dos gabinetes, paredes físicas, aberturas das pontes, sombra de contato e projeção, renderização real do shader, estabilidade ao mover a câmera, animação e preservação da interface.
- Testes de mundo, campanha, integração do ambiente, objetivos, vegetação, ecologia do chão e prólogo verificam circulação, progressão e acessibilidade.
- `tools/review_district.gd` gera nove capturas em `captures/distrito-integrado`. A variável `P17_DISTRICT_CAPTURE_DIR` permite escolher outra pasta.

As novas artes e seus prompts estão registrados em `assets/station/DISTRICT_SOURCES.md`.
