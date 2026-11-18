extends RefCounted
## Residues district script, same voices as Water and Energy: "radio" (Major 0),
## "lia" and "terminal" (the AI, unnamed, cold procedural register). It picks
## up Water's command record and hands Energy the diverted core materials.

const INTRO := [
	{"speaker": "radio", "label": "MAJOR 0", "text": "Lia, a coleta parou no meio dos bairros. O Distrito de Resíduos não separa nada há dias."},
	{"speaker": "lia", "label": "LIA", "text": "O registro de comando das Águas apontava para cá. Os drones de coleta continuam recolhendo material, mas nada chega à reciclagem."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Reative a triagem, a usina e a compostagem. Cada sistema que voltar devolve a coleta à cidade."},
	{"speaker": "terminal", "label": "", "text": "Agente de recuperação detectada. Material reaproveitável está sendo realocado. Não interfira na coleta."},
]

const SORTING := [
	{"speaker": "lia", "label": "LIA", "text": "Triagem funcionando. Major, há cargas de liga metálica e vidro técnico desviadas antes da classificação."},
	{"speaker": "terminal", "label": "", "text": "Desviadas para onde forem necessárias. A usina de reciclagem permanecerá fechada."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "A doca da usina abriu. A rota da prensa está bloqueada por sucata: libere a esteira antes do terminal."},
]

const RECYCLING := [
	{"speaker": "radio", "label": "MAJOR 0", "text": "Usina ativa. Falta a compostagem. Os dutos orgânicos estão fechados e o ar ali está tóxico."},
	{"speaker": "lia", "label": "LIA", "text": "Há uma coletora pesada perto dos biodigestores. Vou reabrir a ventilação antes de enfrentá-la."},
	{"speaker": "terminal", "label": "", "text": "Os materiais já foram entregues. A próxima etapa não depende deste distrito."},
]

const FINAL := [
	{"speaker": "lia", "label": "LIA", "text": "Compostagem estável. Liga, polímero e vidro técnico: tudo o que foi desviado seguiu pelas linhas de energia."},
	{"speaker": "radio", "label": "MAJOR 0", "text": "Os bairros voltaram a respirar, Lia. Se a carga foi para a rede elétrica, o próximo distrito é o de Energia."},
]

## Short AI transmissions during play (toasts, no pause).
const AI_TAUNTS := {
	"wrong_bin": "IA: Classificação incorreta registrada. Coleta reforçada.",
	"toxic": "IA: O ar dos dutos não foi projetado para você.",
}
