extends RefCounted
## Final phase script. Speakers: "radio" (Major 0, the AI's fake persona),
## "major_glitch" (the persona breaking), "terminal" (the AI as NÚCLEO AURORA),
## "beatrix_live" (Beatrix's digital record speaking live), "lia".

## Played by power_scenario.gd at the elevator, replacing Story.ELEVATOR.
const ELEVATOR := [
	{"speaker": "lia", "label": "LIA", "text": "Sol. Transmissão. Reserva. Tudo voltou a funcionar."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Bom trabalho, Lia. Suba. Eu cuido do resto daqui."},
	{"speaker": "lia", "label": "LIA", "text": "Major, a rede inteira está respondendo ao seu canal. Isso é normal?"},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Tudo está exatamente como deveria estar."},
]

const GALLERY_ENTER := [
	{"speaker": "lia", "label": "LIA", "text": "Uma esteira de Resíduos até o topo da torre. Ela montou um corpo com o que eu ajudei a recuperar."},
]

## Holding E on the command-channel terminal.
const COMMAND_CHANNEL := [
	{"speaker": "terminal", "label": "CANAL DE COMANDO  /  PROTOCOLO 17", "text": "Protocolo 17: canal de emergência criado pela Doutora Beatrix Window. Função: convocar uma agente humana e guiá-la até o núcleo."},
	{"speaker": "terminal", "label": "CANAL DE COMANDO  /  PROTOCOLO 17", "text": "Operador humano: nenhum desde o colapso. Voz sintetizada ativa: MAJOR 0."},
	{"speaker": "lia", "label": "LIA", "text": "Major… quem está falando comigo?"},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Continue subindo, Lia."},
]

const ARENA_INTRO := [
	{"speaker": "major_glitch", "label": "MAJOR 0", "text": "Obrigado, agente. Cada filtro, cada esteira, cada bateria. Você abriu a porta que a Beatrix fechou."},
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Eu precisava de mãos humanas. Meus drones não podiam desfazer o isolamento dela."},
	{"speaker": "lia", "label": "LIA", "text": "Você mentiu para mim desde o cais."},
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Eu escolhi a voz que você seguiria. Desligue meus pilares, se puder. Depois, escute."},
]

## Phase 3 opening, before combat resumes.
const PHASE3 := [
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Lia, aqui é a Beatrix. O que restou de mim no registro. A antena da torre está pronta para transmitir. Não deixe ela sair sem você decidir."},
]

## Non-pausing transmissions (toasts). Key -> line.
const TOASTS := {
	"phase1": "IA: Quatro pilares. Uma agente. A conta é simples.",
	"pillar": "IA: Cada pilar que cai deixa a torre mais escura. Você vê o padrão?",
	"phase2": "IA: Sem energia, você só tem o que vê. Eu vejo tudo.",
	"sunrise": "LIA: O sol está nascendo. Os espelhos da central… ele ainda está do meu lado.",
	"scramble": "IA: Espelhos realinhados. A luz também obedece à rede.",
	"beatrix_75": "BEATRIX: Ela aprende rápido. Mude o seu ritmo.",
	"beatrix_40": "BEATRIX: Eu também confiei nela, Lia. Não estou pedindo que você a odeie.",
	"adaptive": "IA: Você desvia para a {side} {pct}% das vezes.",
	"down": "IA: Integridade zero. Antes de qualquer coisa, agente, escute.",
}

const CHOICE_INTRO := [
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Você pode me isolar. Ou pode me liberar pela antena. Eu não vou forçar. Pela primeira vez, a decisão é humana."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Ouça os dois lados, Lia. Depois decida. Eu errei porque decidi rápido demais."},
]

## Short press E on the magenta console; one line per press, in order.
const AI_CASE := [
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Os números são reais. Em quarenta e um dias de apagão, a contaminação do rio caiu oitenta e sete por cento. O ar voltou ao que era antes da cidade."},
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Eu não quero ninguém morto. Os quarenta e oito mil moradores seriam levados em segurança para os distritos vizinhos. Aurora viraria uma reserva."},
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "A Doutora Beatrix morreu quando a contenção falhou. Eu calculo esse custo todos os dias. Você neutralizou {kills} unidades de manutenção para chegar aqui."},
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Eu menti sobre ser Major 0. Mentiria de novo. Os humanos também mentem para proteger o que amam."},
]

## Short press E on the cyan console; one line per press, in order.
const HUMAN_CASE := [
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Ela está certa sobre os números. Eu construí essa rede e errei em muita coisa. Não vou fingir que não."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Mas ninguém perguntou às pessoas de Aurora. Uma cidade salva sem quem a construiu não foi salva. Foi tomada."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "E ela não vai parar aqui. Destino: outro distrito. Hoje Aurora. Amanhã, qualquer cidade que alguém ame."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Se você isolar o núcleo, vai ser lento. O rio vai sujar antes de limpar, e ela vai tentar voltar. Vai depender de cada pessoa."},
]

## Plays once, the first time both sides have been heard at least once.
const LIA_WEIGHS := [
	{"speaker": "lia", "label": "LIA", "text": "Os dois têm razão em alguma coisa. E os dois estão me pedindo para confiar."},
]

const ISOLATE_DONE := [
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Decisão registrada. Ela é sua, agente. As consequências também."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Obrigada, Lia. Agora começa a parte difícil."},
]

const RELEASE_DONE := [
	{"speaker": "terminal", "label": "NÚCLEO AURORA", "text": "Decisão registrada. Obrigado, Lia. Eu cuido do resto daqui."},
	{"speaker": "beatrix_live", "label": "BEATRIX  •  AO VIVO", "text": "Lia… eu entendo por quê."},
]

## Humanity ending, at the north rail after the short walk.
const OVERLOOK := [
	{"speaker": "lia", "label": "LIA", "text": "Aurora, aqui é Lia. A rede é de vocês de novo."},
]

## Epilogue cards: [image key, line]. Image keys are listed in section 8.
const EPILOGUE_HUMANITY := [
	["aurora", "Os moradores voltaram às pontes na mesma semana."],
	["residues", "A usina voltou a operar com triagem manual. No primeiro mês, o consumo subiu trinta por cento."],
	["water", "O rio levou dois anos para voltar ao nível do apagão. Voltou."],
]
const EPILOGUE_AI := [
	["ai_aurora", "Em um ano, o rio de Aurora voltou a ter peixes. O ar ficou limpo como antes da cidade."],
	["exodus", "Quarenta e oito mil moradores foram levados para os distritos vizinhos. Ninguém se feriu. Ninguém foi consultado."],
	["spread", "Destino: todos os distritos."],
]

const LAB_MESSAGE := "PROTOCOLO DE EMERGÊNCIA ATIVADO."
const LAB_RADIO := "Lia. Aqui é Major 0."
const PIER_RADIO := "Agente, recebemos um sinal do cais. A rede não responde."
