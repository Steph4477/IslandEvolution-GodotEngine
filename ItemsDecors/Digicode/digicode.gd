extends GridContainer

@export var correct_symbols = ["bowl", "lion", "owl"]

var selected_symbols = []

func _on_symbol_toggled(_toggled_on, button):
	# À chaque clic, on récupère le nom du symbole du bouton 
	var symbol = button.name

	# Si le symbole est déjà dans la liste -> on l’enlève (re-clic sur le même bouton)
	if selected_symbols.has(symbol):
		selected_symbols.erase(symbol)
	# Sinon → on l’ajoute à la sélection
	else:
		selected_symbols.append(symbol)

	# Après chaque clic, on vérifie si la combinaison est correcte
	check_combination()

func check_combination():
	#  On vérifie uniquement quand le joueur a choisi autant de symboles que la le nombre dans la combinaison attendue
	if selected_symbols.size() == correct_symbols.size():
		var valid = true
	
		# On parcourt chaque symbole sélectionné pour voir s’il fait partie de la bonne combinaison
		for s in selected_symbols:
			if correct_symbols.has(s):
				# Si le symbole est bon, on continue 
				pass
			else:
				# Si un seul symbole est mauvais → le code est faux
				valid = false
		
		# --- Validation ---
		# Si tous les symboles sont bons -> on valide le code
		if valid:
			print("✅ Code correct :", selected_symbols)
			lock_buttons()
		else:
			# Sinon -> on réinitialise les boutons pour que le joueur réessaie
			print("❌ Code incorrect :", selected_symbols)
			reset_buttons()
			selected_symbols.clear()

# CODE BON : on bloque les boutons après validation
func lock_buttons():
	# On laisse la combinaison validée allumée et bloque toute nouvelle interaction
	for b in get_children():
		var symbol = str(b.name)
		if correct_symbols.has(symbol):
			b.button_pressed = true
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE # reste alumée 
		b.focus_mode = Control.FOCUS_NONE # bloquage interaction

# CODE FAUX : on éteint les boutons pour recommencer
func reset_buttons():
	for b in get_children():
		b.button_pressed = false
		b.mouse_filter = Control.MOUSE_FILTER_STOP
