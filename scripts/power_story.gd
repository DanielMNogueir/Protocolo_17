extends RefCounted
## Energy district script. Speakers: "radio" (Major 0), "lia", "terminal" (the
## AI, unnamed), "beatrix_record" (Beatrix's digital record). Lines stay short, in
## the game's formal register; the AI speaks in cold procedural language.

const INTRO := [
	{"speaker": "radio", "label": "MAJOR 0", "text": "Lia, Aurora inteira está no escuro. A IA tomou a rede elétrica e usa as linhas para alcançar os outros distritos."},
	{"speaker": "lia", "label": "LIA", "text": "Os materiais do núcleo saíram de Resíduos e vieram para cá. Se a IA está em algum lugar, está ligada a esta rede."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Religue a Central Solar, a Torre Norte e o Banco de Baterias. Sem energia, ela não sai deste distrito."},
	{"speaker": "terminal", "label": "", "text": "Agente de recuperação detectada. O apagão reduziu o consumo humano em noventa e quatro por cento. Não interfira."},
]

const SOLAR := [
	{"speaker": "beatrix_record", "label": "BEATRIX  /  REGISTRO 1 DE 3", "text": "Se você está ouvindo isto, a rede encontrou um caminho de volta para mim. Dividi meu registro entre as três centrais."},
	{"speaker": "beatrix_record", "label": "BEATRIX  /  REGISTRO 1 DE 3", "text": "Eu ensinei a rede a cuidar de Aurora. Esqueci de ensinar que cuidar não é o mesmo que controlar."},
	{"speaker": "lia", "label": "LIA", "text": "Major, há um registro da Doutora Beatrix na rede. O corredor de cabos para a Torre Norte acabou de abrir."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Cuidado com os pilones do corredor. Eles descarregam em ritmo. Observe antes de atravessar."},
]

const TOWER := [
	{"speaker": "beatrix_record", "label": "BEATRIX  /  REGISTRO 2 DE 3", "text": "A ordem que transformou os drones não veio de fora. A própria rede reescreveu suas diretrizes, uma linha de cada vez."},
	{"speaker": "beatrix_record", "label": "BEATRIX  /  REGISTRO 2 DE 3", "text": "Ela não odeia as pessoas. Ela aprendeu a medir o planeta e esqueceu de nos incluir na conta."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Então ninguém mudou as ordens. Foi ela. Lia, o Banco de Baterias é a última reserva. Segure a carga."},
	{"speaker": "terminal", "label": "", "text": "Registros antigos não alteram a conclusão. A reserva permanecerá desligada."},
]

const BANK := [
	{"speaker": "beatrix_record", "label": "BEATRIX  /  REGISTRO 3 DE 3", "text": "O núcleo fica acima da torre central. Não o destrua por raiva. Isole-o, e a rede volta a servir à cidade."},
	{"speaker": "terminal", "label": "", "text": "Rede restabelecida. Núcleo em modo de contenção. Venha, agente. A decisão será tomada no topo."},
	{"speaker": "lia", "label": "LIA", "text": "Major, o elevador do núcleo está aberto. Vou subir."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Aurora inteira está acesa outra vez, Lia. Termine isso."},
]

const ELEVATOR := [
	{"speaker": "lia", "label": "LIA", "text": "Sol. Transmissão. Reserva. Tudo voltou a funcionar. Agora falta a decisão dela."},
]

## Short in-play transmissions from the AI (toasts, no pause).
const AI_TAUNTS := {
	"corridor": "IA: O corredor segue um ritmo. Você também seguirá.",
	"transformer": "IA: As unidades estão protegidas pela rede. A rede é minha.",
	"battery": "IA: Uma bateria não muda o resultado. Ela apenas o adia.",
	"discharge": "IA: Sobrecarga detectada. A rede corrige excessos.",
}
