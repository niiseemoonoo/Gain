//Allows fast querying of which effects have which numeric_modifier()s.

//Modifiers are lower case.
static
{
	boolean [effect][string] __modifiers_for_effect;
	boolean [string][effect] __effects_for_modifiers;
	boolean [effect] __effect_contains_non_constant_modifiers; //meaning, numeric_modifier() cannot be cached
	boolean [effect][item] __items_for_effect;
	boolean [effect][skill] __skills_for_effect;
}
void initialiseModifiers()
{
	if (__modifiers_for_effect.count() != 0) return;
	//boolean [string] modifier_types;
	//boolean [string] modifier_values;
	foreach e in $effects[]
	{
		string string_modifiers = e.string_modifier("Modifiers");
        if (string_modifiers == "") continue;
        if (string_modifiers.contains_text("Avatar: ")) continue; //FIXME parse properly?
        string [int] first_level_split = string_modifiers.split_string(", ");
        
        foreach key, entry in first_level_split
        {
        	//print_html(entry);
            //if (!entry.contains_text(":"))
            
            string modifier_type;
            string modifier_value;
            if (entry.contains_text(": "))
            {
            	string [int] entry_split = entry.split_string(": ");
                modifier_type = entry_split[0];
                modifier_value = entry_split[1];
            }
            else
            	modifier_type = entry;
            
            
            string modifier_type_converted = modifier_type;
            
            //convert modifier_type to modifier_type_converted:
            //FIXME is this all of them?
            if (modifier_type_converted == "Combat Rate (Underwater)")
            	modifier_type_converted = "Underwater Combat Rate";
            else if (modifier_type_converted == "Experience (familiar)")
                modifier_type_converted = "Familiar Experience";
            else if (modifier_type_converted == "Experience (Moxie)")
                modifier_type_converted = "Moxie Experience";
            else if (modifier_type_converted == "Experience (Muscle)")
                modifier_type_converted = "Muscle Experience";
            else if (modifier_type_converted == "Experience (Mysticality)")
                modifier_type_converted = "Mysticality Experience";
            else if (modifier_type_converted == "Experience Percent (Moxie)")
                modifier_type_converted = "Moxie Experience Percent";
            else if (modifier_type_converted == "Experience Percent (Muscle)")
                modifier_type_converted = "Muscle Experience Percent";
            else if (modifier_type_converted == "Experience Percent (Mysticality)")
                modifier_type_converted = "Mysticality Experience Percent";
            else if (modifier_type_converted == "Mana Cost (stackable)")
                modifier_type_converted = "Stackable Mana Cost";
            else if (modifier_type_converted == "Familiar Weight (hidden)")
                modifier_type_converted = "Hidden Familiar Weight";
            else if (modifier_type_converted == "Meat Drop (sporadic)")
                modifier_type_converted = "Sporadic Meat Drop";
            else if (modifier_type_converted == "Item Drop (sporadic)")
                modifier_type_converted = "Sporadic Item Drop";
            
            modifier_type_converted = modifier_type_converted.to_lower_case();
            __modifiers_for_effect[e][modifier_type_converted] = true;
            __effects_for_modifiers[modifier_type_converted][e] = true;
            if (modifier_value.contains_text("[") || modifier_value.contains_text("\""))
            	__effect_contains_non_constant_modifiers[e] = true;
            if (modifier_type_converted ≈ "muscle percent")
            {
            	__modifiers_for_effect[e]["muscle"] = true;
            	__effects_for_modifiers["muscle"][e] = true;
            }
            if (modifier_type_converted ≈ "mysticality percent")
            {
                __modifiers_for_effect[e]["mysticality"] = true;
                __effects_for_modifiers["mysticality"][e] = true;
            }
            if (modifier_type_converted ≈ "moxie percent")
            {
                __modifiers_for_effect[e]["moxie"] = true;
                __effects_for_modifiers["moxie"][e] = true;
            }
            
            /*if (e.numeric_modifier(modifier_type_converted) == 0.0 && modifier_value.length() > 0 && e.string_modifier(modifier_type_converted) == "")// && !__effect_contains_non_constant_modifiers[e])
            {
            	//print_html("No match on \"" + modifier_type_converted + "\"");
                print_html("No match on \"" + modifier_type_converted + "\" for " + e + " (" + string_modifiers + ")");
            }*/
            //modifier_types[modifier_type] = true;
            //modifier_values[modifier_value] = true;
        }
        //return;
	}
	foreach it in $items[]
	{
		effect e = it.effect_modifier("effect");
		if (e == $effect[none]) continue;
		__items_for_effect[e][it] = true;
	}
	foreach s in $skills[]
	{
		effect e = s.to_effect();
		if (e == $effect[none]) continue;
		__skills_for_effect[e][s] = true;
	}
	/*print_html("Types:");
	foreach type in modifier_types
	{
		print_html(type);
	}
	print_html("");
    print_html("Values:");
    foreach value in modifier_values
    {
        print_html(value);
    }*/
}
initialiseModifiers();

//FIXME support asdon
string __gain_version = "1.3.2";
boolean __gain_setting_confirm = false;

boolean [item] __modify_blocked_items;
boolean [skill] __modify_blocked_skills;
boolean [effect] __blocked_effects;
boolean [effect] __fixed_blocked_effects = $effects[cowrruption,Visions of the Deep Dark Deeps, Spice Haze,Slippery and Speedy,Legendary Pasta Eyeball];

int __maximum_meat_to_spend = 100000;
boolean __setting_silent = false;
boolean __setting_ignore_percentages = false;
boolean __setting_allow_limited_buffs = false;

boolean __setting_simulation_only = false;
float[string] __simulation_modifier_bonus;
buffer __simulation_output;
int __simulation_effect_min_turns = 999999999; // something "large", lol
int __simulation_effect_max_turns = -1;

int __starting_meat = -1;
int __meat_spent = 0;

void initializeBlockedItems() {
	//we don't use the pirate items because mafia doesn't acquire them properly - if pirate tract is 301 in the mall, it'll try to get it from the store, and fail
	foreach it in $items[M-242,snake,sparkler,pirate tract,pirate pamphlet,pirate brochure,elven suicide capsule,ghost dog chow, bottle of bubbles, yummy tummy bean] {
		__modify_blocked_items[it] = true;
	}

	boolean isAutumn = $strings[09,10,11] contains now_to_string("MM");
	if (!isAutumn) {
		__modify_blocked_items[$item[crystallized pumpkin spice]] = true;
	}
}
initializeBlockedItems();

if (my_class() == $class[turtle tamer])
{
	foreach s in $skills[Blessing of the Storm Tortoise,Blessing of She-Who-Was,Blessing of the War Snapper]
		__modify_blocked_skills[s] = true;
}
else if (my_class() == $class[pastamancer])
{
	foreach t in $thralls[]
		__modify_blocked_skills[t.skill] = true;
}

foreach sk in $skills[Aug. 6th: Fresh Breath Day!, Aug. 7th: Lighthouse Day!, Cincho: Party Soundtrack] {
	__modify_blocked_skills[sk] = true;
}


boolean haveEquipment(item equipment) {
	return item_amount(equipment) > 0 || have_equipped(equipment);
}

void initializeRequiredEquipment() {
	if (!haveEquipment($item[April Shower Thoughts Shield])) {
		// special effects added to normal skills we may still want to use
		foreach e in $effects[Slippery as a Seal,Strength of the Tortoise,Tubes of Universal Meat,Lubricating Sauce,Disco over Matter,Mariachi Moisture] {
			__blocked_effects[e] = true;
		}
	}
}
initializeRequiredEquipment();


boolean [effect] __limited_effects;
__limited_effects[to_effect("Blessing of your favorite Bird")] = true;
__limited_effects[to_effect("Blessing of the Bird")] = true;
__limited_effects[to_effect("Triple-Sized")] = true;
__limited_effects[to_effect("Invisible Avatar")] = true;


static
{
	boolean [int][effect] __mutually_exclusive_effect_sets;
	boolean [effect] __effect_is_mutually_exclusive;
	boolean [skill] __accordion_thief_songs = $skills[The Moxious Madrigal,The Magical Mojomuscular Melody,Cletus's Canticle of Celerity,The Power Ballad of the Arrowsmith,The Polka of Plenty,Jackasses' Symphony of Destruction,Fat Leon's Phat Loot Lyric,Brawnee's Anthem of Absorption,The Psalm of Pointiness,Stevedave's Shanty of Superiority,Aloysius' Antiphon of Aptitude,The Ode to Booze,The Sonata of Sneakiness,Carlweather's Cantata of Confrontation,Ur-Kel's Aria of Annoyance,Dirge of Dreadfulness,The Ballad of Richie Thingfinder,Benetton's Medley of Diversity,Elron's Explosive Etude,Chorale of Companionship,Prelude of Precision,Donho's Bubbly Ballad,Cringle's Curative Carol,Inigo's Incantation of Inspiration]; //'
	boolean [effect] __accordion_thief_songs_effects;
	
	foreach s in __accordion_thief_songs
	{
		__accordion_thief_songs_effects[s.to_effect()] = true;
	}
}


float gain_fabs(float v)
{
	if (v >= 0.0) return v;
	return -v;
}

void initialiseMutuallyExclusiveEffects()
{
	if (__mutually_exclusive_effect_sets.count() > 0) return;
	
	__mutually_exclusive_effect_sets[__mutually_exclusive_effect_sets.count()] = $effects[Snarl of the Timberwolf,Scowl of the Auk,Stiff Upper Lip,Patient Smile,Quiet Determination,Arched Eyebrow of the Archmage,Wizard Squint,Quiet Judgement,Icy Glare,Wry Smile,Disco Leer,Disco Smirk,Suspicious Gaze,Knowing Smile,Quiet Desperation];
	__mutually_exclusive_effect_sets[__mutually_exclusive_effect_sets.count()] = $effects[Song of the North,Song of Slowness,Song of Starch,Song of Sauce,Song of Bravado];
	__mutually_exclusive_effect_sets[__mutually_exclusive_effect_sets.count()] = $effects[purple tongue,green tongue,orange tongue,red tongue,blue tongue];
	__mutually_exclusive_effect_sets[__mutually_exclusive_effect_sets.count()] = $effects[Puissant Pressure, Perspicacious Pressure, Pulchritudinous Pressure, Possessive Pressure, Perceptive Pressure, Proficient Pressure, Pneumatic];
	__mutually_exclusive_effect_sets[__mutually_exclusive_effect_sets.count()] = $effects[Spirit of Cayenne,Spirit of Peppermint,Spirit of Garlic,Spirit of Wormwood,Spirit of Bacon Grease];
	
	foreach key in __mutually_exclusive_effect_sets
	{
		foreach e in __mutually_exclusive_effect_sets[key]
			__effect_is_mutually_exclusive[e] = true;
	}
}
initialiseMutuallyExclusiveEffects();

float my_active_basestat(stat s)
{
	float v = my_basestat(s);
	float limit = numeric_modifier(s + " Limit");
	
	if (limit > 0 && limit < v)
		v = limit;
	if (v < 0) v = 1;
	return v;
}

float numeric_modifier_including_percentages_on_base_modifiers(effect e, string modifier_name)
{
	if (modifier_name ≈ "any")
	{
		return 1.0;
	}
	float v = e.numeric_modifier(modifier_name);
	if (__setting_ignore_percentages)
		return v;
	if (modifier_name ≈ "muscle")
	{
		float stat_percent = e.numeric_modifier("muscle percent");
		if (stat_percent != 0.0)
			v += stat_percent / 100.0 * my_active_basestat($stat[muscle]);
	}
	if (modifier_name ≈ "mysticality")
	{
		float stat_percent = e.numeric_modifier("mysticality percent");
		if (stat_percent != 0.0)
			v += stat_percent / 100.0 * my_active_basestat($stat[mysticality]);
	}
	if (modifier_name ≈ "moxie")
	{
		float stat_percent = e.numeric_modifier("moxie percent");
		if (stat_percent != 0.0)
			v += stat_percent / 100.0 * my_active_basestat($stat[moxie]);
	}
	if (modifier_name ≈ "maximum mp")
	{
		//FIXME use maximum MP percent properly? I just made this formula up, it's wrong. so wrong.
		v += numeric_modifier_including_percentages_on_base_modifiers(e, "mysticality") / 100.0 * (1.0 + numeric_modifier("Maximum MP Percent") / 100.0);
	}
	if (modifier_name ≈ "maximum hp")
	{
		//FIXME use maximum HP percent properly? I just made this formula up, it's wrong. so wrong.
		v += numeric_modifier_including_percentages_on_base_modifiers(e, "muscle") / 100.0 * (1.0 + numeric_modifier("Maximum HP Percent") / 100.0);
	}
	return v;
}


void blockLimitedBuffs()
{
	if (__setting_allow_limited_buffs) return;
	__modify_blocked_skills[to_skill("Visit your Favorite Bird")] = true; //once/day
	__modify_blocked_skills[to_skill("Seek out a Bird")] = true; //limited a day
	__modify_blocked_skills[to_skill("CHEAT CODE: Triple Size")] = true;
	__modify_blocked_skills[to_skill("CHEAT CODE: Invisible Avatar")] = true;
	
	foreach skill_name in $strings[Feel Pride,Feel Excitement,Feel Hatred,Feel Lonely,Feel Nervous,Feel Envy,Feel Disappointed,Feel Lost,Feel Nostalgic,Feel Peaceful,Feel Superior]
	{
		skill s = skill_name.to_skill();
		if (s == $skill[none]) continue;
		__modify_blocked_skills[s] = true;
	}

	// Everything looks beige
	foreach s in $skills[Pull down your crepe paper phrygian cap,Look through your crepe paper pie clip,Play with your crepe paper puzzle,Embrace polka]
	{
		__modify_blocked_skills[s] = true;
	}

	// How to value scaling stat costs?
	foreach s in $skills[BCZ: Blood Bath,BCZ: Dial it up to 11,BCZ: Sweat Equity]
	{
		__modify_blocked_skills[s] = true;
	}
}


Record ModifierUpkeepSettings
{
	string modifier_name;
	float minimum_value;
	int minimum_turns_wanted;
	
	int reasonable_turns_wanted;
	//FIXME MPA, etc
	
	float maximum_efficiency;
	boolean maximum_efficiency_set;
};


int MODIFIER_UPKEEP_ENTRY_TYPE_UNKNOWN = 0;
int MODIFIER_UPKEEP_ENTRY_TYPE_ITEM = 1;
int MODIFIER_UPKEEP_ENTRY_TYPE_SKILL = 2;

Record ModifierUpkeepEntry
{
	int type;
	effect e;
	item it;
	skill s;
	int turns_gotten_from_source;
};

string ModifierUpkeepEntryDescription(ModifierUpkeepEntry entry, string modifier_name)
{
	buffer out;
	if (entry.s != $skill[none])
	{
		out.append("Skill " + entry.s);
	}
	if (entry.it != $item[none])
	{
		out.append("Item " + entry.it);
	}
	out.append(": ");
	out.append(entry.turns_gotten_from_source);
	out.append(" turns of " );
	out.append(entry.e);
	float modifier_value = entry.e.numeric_modifier_including_percentages_on_base_modifiers(modifier_name);
	if (modifier_value > 0)
		out.append(", +");
	else
		out.append(", ");
	out.append(modifier_value + " " + modifier_name);
	return out;
}

float ModifierUpkeepEntryEfficiency(ModifierUpkeepEntry entry, ModifierUpkeepSettings settings)
{
	//FIXME change this calculation; problem:
	//+100% myst on 100 base myst versus 1000 base myst have wildly different efficiencies
	//use a percentage-based improvement system again
	//maybe it should be something like, be willing to spend X meat to get +1% of an improvement per turn
	//issues: -combat at zero, +item at zero, etc
	//how do we "scale"?
	//maybe use a "base" value depending on what it is? idk
	
	
	float cost = entry.it.historical_price() + entry.s.mp_cost() * 2; //meat per MP estimate
	if (entry.it != $item[none] && !entry.it.tradeable) //FIXME approx
		cost += 100.0;
	if (entry.it != $item[none] && entry.it.reusable && entry.it.available_amount() > 0)
		cost = 0.0;
	//if (entry.s != $skill[none])
		//print_html("•" + entry.s + ": "  + cost);
	if (cost <= 0.0) return 0.0;
	float turns_per_use = MIN(settings.reasonable_turns_wanted, entry.turns_gotten_from_source);
	float modifier_gained = MIN(settings.minimum_value - numeric_modifier(settings.modifier_name), entry.e.numeric_modifier_including_percentages_on_base_modifiers(settings.modifier_name));
	
	float combined = (modifier_gained * turns_per_use);
	if (combined == 0.0)
		return 10000.0;
	//if (entry.s != $skill[none])
		//print_html(entry.s + ": " + cost + ", " + combined);
	return cost / combined;
}

string[int] GetAllModifiers(effect e) {
	string[int] modifier_names;
	string[int] modifiers = e.string_modifier("modifiers").split_string(", ");
	foreach _, full_modifier in modifiers {
		string modifier_name = full_modifier.split_string(": ")[0];
		modifier_names[modifier_names.count()] = modifier_name.to_lower_case();
	}
	return modifier_names;
}

boolean isBetween(float value, float low, float high) {
	return (low < value && value < high);
}

void SimulateBuff(string modifier_name, float value)
{
	float value_to_add = value;

	if (modifier_name == "combat rate") {
		float current_value = numeric_modifier(modifier_name) + __simulation_modifier_bonus[modifier_name];
		int value_remaining = value;
		value_to_add = 0;

		int increment = 1;
		if (value < 0)
			increment = -1;

		// soft cap
		while ((current_value + value_to_add).isBetween(-25, 25)) {
			if (value_remaining == 0) {
				break;
			}
			value_remaining -= increment;
			value_to_add += increment;
		}
		// hard cap
		while ((current_value + value_to_add).isBetween(-35, 35)) {
			if (value_remaining == 0) {
				break;
			}
			value_remaining -= increment;
			value_to_add += (increment.to_float() / 5);
		}
	}

	__simulation_modifier_bonus[modifier_name] += value_to_add;
}

void SimulateModifierUpkeep(ModifierUpkeepEntry entry, ModifierUpkeepSettings settings, int qty)
{
    int num_turns_gained = qty * entry.turns_gotten_from_source;
	__simulation_effect_min_turns = MIN(__simulation_effect_min_turns, num_turns_gained);
	__simulation_effect_max_turns = MAX(__simulation_effect_max_turns, num_turns_gained);

	if (have_effect(entry.e) == 0) {
		foreach _, modifier_name in GetAllModifiers(entry.e) {
			float value = entry.e.numeric_modifier_including_percentages_on_base_modifiers(modifier_name);
			SimulateBuff(modifier_name, value);
		}
	}

	if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_ITEM)
		__simulation_output.append("use " + qty + " " + entry.it.name + "; ");
	if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_SKILL)
		__simulation_output.append("cast " + qty + " " + entry.s.name + "; ");
}

void ModifierUpkeepEffects(ModifierUpkeepSettings settings)
{
	if (settings.minimum_turns_wanted < 0) settings.minimum_turns_wanted = 1;
	if (settings.reasonable_turns_wanted == 0) settings.reasonable_turns_wanted = 20;
	if (__starting_meat < 0) __starting_meat = my_meat();
	
	settings.modifier_name = settings.modifier_name.to_lower_case();
	
	ModifierUpkeepEntry [int] possible_sources;
	boolean want_positive = settings.minimum_value >= 0;
	
	//Generate items:
	
	//foreach it in $items[]
	boolean within_path_g_lover = my_path().name == "G-Lover";
	boolean within_nuclear_autumn = my_path().name == "Nuclear Autumn";
	
	boolean [effect] effects_for_modifier = __effects_for_modifiers[settings.modifier_name];
	
	if (settings.modifier_name ≈ "any")
	{
		effects_for_modifier = $effects[];
	}
	
	foreach e in effects_for_modifier
	{
		foreach it in __items_for_effect[e]
		{
			//effect e = it.effect_modifier("effect");
			//if (e == $effect[none]) continue;
			//if (!__modifiers_for_effect[e][settings.modifier_name]) continue;
			if (!can_interact())
			{
				//within ronin:
				if (it.available_amount() + it.creatable_amount() == 0) continue;
		
				if (it.available_amount() == 0 && it.creatable_amount() != 0)
				{
					//FIXME "does this cost a turn to make"
					string craft_type = it.craft_type();
					if (craft_type.contains_text("Cooking (fancy)"))
						continue;
				}
			}
		
			if (__modify_blocked_items[it]) continue;
			if ($items[Shrieking Weasel holo-record,Power-Guy 2000 holo-record,Lucky Strikes holo-record,EMD holo-record,Superdrifter holo-record,The Pigs holo-record,Drunk Uncles holo-record] contains it && !within_nuclear_autumn) continue;
		
			if (it.fullness > 0 || it.inebriety > 0 || it.spleen > 0) //FIXME allow such things?
				continue;
			float modifier_not_quite_right = e.numeric_modifier_including_percentages_on_base_modifiers(settings.modifier_name);
			if (modifier_not_quite_right < 0.0 && want_positive)
				continue;
			if (modifier_not_quite_right > 0.0 && !want_positive)
				continue;
			if (my_path().name == "G-Lover")
			{
				if (!it.contains_text("g") && !it.contains_text("G"))
					continue;
				if (!e.contains_text("g") && !e.contains_text("G"))
					continue;
			}
			ModifierUpkeepEntry entry;
			entry.e = e;
			entry.type = MODIFIER_UPKEEP_ENTRY_TYPE_ITEM;
			entry.it = it;
			entry.turns_gotten_from_source = it.numeric_modifier("effect duration");
			possible_sources[possible_sources.count()] = entry;
		}
		//Generate skills:
		foreach s in __skills_for_effect[e]
		{
			//effect e = s.to_effect();
			//if (e == $effect[none]) continue;
			//if (!__modifiers_for_effect[e][settings.modifier_name]) continue;
		
			float modifier_not_quite_right = e.numeric_modifier_including_percentages_on_base_modifiers(settings.modifier_name);
			if (modifier_not_quite_right < 0.0 && want_positive)
				continue;
			if (modifier_not_quite_right > 0.0 && !want_positive)
				continue;
			if (within_path_g_lover && !s.contains_text("g") && !s.contains_text("G"))
			{
				continue;
			}
			ModifierUpkeepEntry entry;
			entry.e = e;
			entry.type = MODIFIER_UPKEEP_ENTRY_TYPE_SKILL;
			entry.s = s;
			entry.turns_gotten_from_source = s.turns_per_cast();
			possible_sources[possible_sources.count()] = entry;
		}
	}
	
	/*if ($effect[Become Superficially interested].have_effect() > 0 && settings.modifier_name == "combat rate")
	{
		print("Switching to Become Intensely interested.");
		visit_url("charsheet.php?action=newyouinterest");
	}
	if ($effect[Become Intensely interested].have_effect() > 0 && settings.modifier_name == "-combat")
	{
		print("Switching to Become Superficially interested.");
		visit_url("charsheet.php?action=newyouinterest");
	}
	if (settings.modifier_name == "combat rate" && get_property("_horsery") == "dark horse")
	{
		print("Returning your dark horse.");
		visit_url("place.php?whichplace=town_right&action=town_horsery");
		visit_url("choice.php?whichchoice=1266&option=5");
	}*/
	
	boolean can_access_mall = get_property("autoSatisfyWithMall").to_boolean();
	int breakout = 500;
	float last_loop_value = -1.0;	
	boolean allow_overriding_modifier_value_safety = false;
	boolean first = true;
	
	boolean [effect] dynamic_blocked_effects;

	while (breakout > 0)
	{
		breakout -= 1;
		
		float relevant_value_for_modifier = numeric_modifier(settings.modifier_name);
		
		if (settings.modifier_name ≈ "muscle")
			relevant_value_for_modifier = my_buffedstat($stat[muscle]);
		if (settings.modifier_name ≈ "mysticality")
			relevant_value_for_modifier = my_buffedstat($stat[mysticality]);
		if (settings.modifier_name ≈ "moxie")
			relevant_value_for_modifier = my_buffedstat($stat[moxie]);
		if (settings.modifier_name ≈ "maximum mp")
			relevant_value_for_modifier = my_maxmp();
		if (settings.modifier_name ≈ "maximum hp")
			relevant_value_for_modifier = my_maxhp();
		if (settings.modifier_name ≈ "familiar weight")
			relevant_value_for_modifier = numeric_modifier(settings.modifier_name) + my_familiar().familiar_weight(); //FIXME support feasted familiars, because that's a complete pain

		if (__setting_simulation_only)
			relevant_value_for_modifier += __simulation_modifier_bonus[settings.modifier_name];
			
		boolean satisfied = true;
		if (settings.minimum_value >= 0.0 && settings.minimum_value > relevant_value_for_modifier)
			satisfied = false;
		if (settings.minimum_value < 0.0 && settings.minimum_value < relevant_value_for_modifier)
			satisfied = false;
		if (satisfied)
			break;
			
		
		if (first)
		{
			first = false;
		}
		else if (!__setting_simulation_only)
		{
			if (last_loop_value == relevant_value_for_modifier && !allow_overriding_modifier_value_safety && !(settings.modifier_name ≈ "any"))
			{
				print("Stopping trying to gain a buff. Value of modifier " + settings.modifier_name + " is " +relevant_value_for_modifier + ", same as the previous " + relevant_value_for_modifier + ".", "red");
				break;
			}
		}
		allow_overriding_modifier_value_safety = false;
		last_loop_value = relevant_value_for_modifier;
			
		if (satisfied)
			break;
			
		if (want_positive)
			sort possible_sources by value.ModifierUpkeepEntryEfficiency(settings);
		else
			sort possible_sources by -value.ModifierUpkeepEntryEfficiency(settings);
		//Issue mall searches for the most likely candidates:
		foreach key, entry in possible_sources
		{
			if (key >= 20) break;
			if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_ITEM && entry.it.tradeable && can_access_mall)
				entry.it.mall_price();
		}
		if (want_positive)
			sort possible_sources by value.ModifierUpkeepEntryEfficiency(settings);
		else
			sort possible_sources by -value.ModifierUpkeepEntryEfficiency(settings);
		
		/*for i from 0 to 20
			print_html("possible_sources[" + i + "] ( " + possible_sources[i].ModifierUpkeepEntryEfficiency(settings) + " ) = " + possible_sources[i].to_json());
		abort("well?");*/
		allow_overriding_modifier_value_safety = false;
		boolean did_execute_one = false;
		foreach key, entry in possible_sources
		{
			if (__blocked_effects contains entry.e) continue;
			if (__fixed_blocked_effects[entry.e]) continue;
			if (dynamic_blocked_effects[entry.e]) continue;
			int meat_cost = 0;
			boolean turn_into_wish = false;
			if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_ITEM)
			{
				if (!entry.it.tradeable && entry.it.available_amount() == 0)
					continue;
				if (entry.it.available_amount() == 0 && !can_access_mall) continue; //no mall, no service
				if (entry.it.tradeable && entry.it.historical_price() >= 100000) //too expensive
					continue;
				if (entry.it.tradeable && can_access_mall)
				{
					meat_cost = entry.it.mall_price();
					if (meat_cost >= 50000 && meat_cost >= $item[pocket wish].mall_price())
					{
						turn_into_wish = true;
						meat_cost = $item[pocket wish].mall_price();
					}
					if (__meat_spent + meat_cost > __maximum_meat_to_spend) continue;
				}
				if (!entry.it.tradeable && !entry.it.reusable)
				{
					if (my_id() == 1557284 && false)
						print_html("<font color=\"red\">examine " + entry.it + "</font>"); //don't use motivational posters, but cheap wind-up clocks are fine
					continue;
				}
				if (entry.it.reusable && entry.it.dailyusesleft == 0) continue;
			}
			if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_SKILL)
			{
				if (!entry.s.have_skill() || !entry.s.is_unrestricted())
					continue;
				if (entry.s.adv_cost() > 0) continue;
				if (entry.s.mp_cost() > my_maxmp()) continue;
				if (entry.s.hp_cost() >= my_hp()) continue; //we might not have restore, so...
				if ($skills[The Ballad of Richie Thingfinder,Benetton's Medley of Diversity,Elron's Explosive Etude,Chorale of Companionship,Prelude of Precision] contains entry.s && (my_class() != $class[accordion thief] || my_level() < 15)) continue; //'
				if (__modify_blocked_skills[entry.s]) continue;
				//if (entry.s.dailylimit > 0 && entry.s.dailylimit < entry.s.timescast) continue; //do not cast past the daily limit, need verification
				
				if ($skills[Blessing of the Storm Tortoise,Blessing of She-Who-Was,Blessing of the War Snapper] contains entry.s && my_class() != $class[turtle tamer])
				{
					//Do not cast the blessings if we have one active already; this causes bouncing when gaining all stats at once.
					if ($effect[Disdain of the War Snapper].have_effect() > 0 || $effect[Disdain of She-Who-Was].have_effect() > 0 || $effect[Disdain of the Storm Tortoise].have_effect() > 0)
					{
						
						continue;
					}
				}
			}
			if ($skills[CHEAT CODE: Triple Size,CHEAT CODE: Invisible Avatar] contains entry.s && $item[powerful glove].available_amount() == 0)
				continue;
			//Limit also applies to recordings:
			if (__accordion_thief_songs_effects contains entry.e && entry.e.have_effect() == 0)
			{
				int song_limit = 3;
				if ($skill[mariachi memory].have_skill());
					song_limit = 4;
				//FIXME other sources
				int songs_have = 0;
				foreach e in __accordion_thief_songs_effects
				{
					if (e.have_effect() > 0)
						songs_have += 1;
				}
				if (songs_have >= song_limit)
					continue;
			}
			if (__effect_is_mutually_exclusive[entry.e])
			{
				//Check if we have it already:
				//FIXME - should we override? Like disco leer should take over icy glare.
				//print_html("checking " + entry.e);
				boolean should_continue = false;
				foreach key in __mutually_exclusive_effect_sets
				{
					if (!__mutually_exclusive_effect_sets[key][entry.e])
						continue;
					int total = 0;
					foreach e in __mutually_exclusive_effect_sets[key]
					{
						total += e.have_effect();
					}
					if (total > 0)
					{
						should_continue = true;
					}
				}
				if (should_continue)
					continue;
			}
			if (entry.e.numeric_modifier_including_percentages_on_base_modifiers(settings.modifier_name) == 0.0) continue;
			if (entry.e.have_effect() >= settings.minimum_turns_wanted) continue;
			float entry_efficiency = entry.ModifierUpkeepEntryEfficiency(settings);
			if (settings.maximum_efficiency_set && settings.maximum_efficiency < gain_fabs(entry_efficiency))
			{
				break;
			}
			if (!__setting_silent)
				print_html("(meat: " + meat_cost + ") " + entry.ModifierUpkeepEntryDescription(settings.modifier_name) + ": " + round(entry_efficiency*1000)/1000.0 + " efficiency");
			
			if (__gain_setting_confirm)
			{
				boolean ready = user_confirm(entry.ModifierUpkeepEntryDescription(settings.modifier_name) + "\nREADY?");
				if (!ready)
					return;
			}
			//if (key >= 40) abort("?");
			
			//execute:
			int before_effect = entry.e.have_effect();
			int max_reasonable_uses = max(1, my_adventures() / entry.turns_gotten_from_source);
			int amount = MAX(1, ceil(to_float(settings.minimum_turns_wanted - entry.e.have_effect()) / MAX(1.0, to_float(entry.turns_gotten_from_source))));
			amount = MIN(max_reasonable_uses, amount);
			
			if (turn_into_wish)
			{
				if (__setting_simulation_only) {
					print("wish for " + entry.e, "red");
				} else {
					abort("wish for " + entry.e);
				}
			}
			else if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_ITEM)
			{
				if (__setting_simulation_only)
				{
					SimulateModifierUpkeep(entry, settings, amount);
				}
				else
				{
					use(amount, entry.it);
				}
			}
			else if (entry.type == MODIFIER_UPKEEP_ENTRY_TYPE_SKILL)
			{
				if (entry.s.mp_cost() > 0)
					max_reasonable_uses = max(1, my_mp() / entry.s.mp_cost());
				if (entry.s.hp_cost() > 0)
					max_reasonable_uses = max(1, (my_hp() - 1) / entry.s.hp_cost());
				
				item [slot] saved_equipment;
				if (!__setting_simulation_only && $skills[CHEAT CODE: Triple Size,CHEAT CODE: Invisible Avatar] contains entry.s && !$Item[powerful glove].have_equipped())
				{
					saved_equipment[$slot[acc1]] = $slot[acc1].equipped_item();
					equip($item[powerful glove], $slot[acc1]);
				}

				int times_to_cast = min(max_reasonable_uses, amount);
				if (__setting_simulation_only)
				{
					SimulateModifierUpkeep(entry, settings, times_to_cast);
				}
				else
				{
					use_skill(times_to_cast, entry.s);
				}

				foreach s, it in saved_equipment
				{
					equip(it, s);
				}
			}
			int after_effect = entry.e.have_effect();

			if (__setting_simulation_only)
			{
				__blocked_effects[entry.e] = true;
			}
			else if (after_effect == before_effect)
			{
				//use 1 future drug: Muscularactum
				//You acquire an effect: The Strength... of the Future (0)
				//zero turns, wasted someone's future drugs
				refresh_status();
				after_effect = entry.e.have_effect();
				if (after_effect == before_effect)
				{
					if (__limited_effects contains entry.e || (entry.s.class == $class[accordion thief]))
					{
						__blocked_effects[entry.e] = true;
						continue;
					}
					else
						abort("Mafia bug: " + entry.ModifierUpkeepEntryDescription(settings.modifier_name) + " did not gain any turns.");
				}
			}
			else if (before_effect != 0 && after_effect < 1000)
				allow_overriding_modifier_value_safety = true;
			if (after_effect >= settings.minimum_turns_wanted)
			{
				dynamic_blocked_effects[entry.e] = true;
			}
			__meat_spent += meat_cost * amount;
			
			did_execute_one = true;
			break;
		}
		if (!did_execute_one) //nothing left
		{
			break;
		}
	}
}



//Example usage:
//float [string] modifiers = {"Initiative":400};
//ModifierUpkeepEffects(modifiers);
void ModifierUpkeepEffects(float [string] minimum_modifiers_want)
{
	foreach modifier_name, minimum in minimum_modifiers_want
	{
		ModifierUpkeepSettings modifier_settings;
		modifier_settings.modifier_name = modifier_name;
		modifier_settings.minimum_value = minimum;
		modifier_settings.minimum_turns_wanted = 1;
		modifier_settings.reasonable_turns_wanted = min(my_adventures(), 20);
		ModifierUpkeepEffects(modifier_settings);
	}
}
void ModifierUpkeepEffects(int [string] minimum_modifiers_want)
{
	float [string] converted;
	foreach modifier_name, minimum in minimum_modifiers_want
	{
		converted[modifier_name] = minimum;
	}
	ModifierUpkeepEffects(converted);
}

void ModifierOutputExampleUsage()
{
	if (__setting_silent) return;
	print_html("<strong>silent</strong>: don't output text (useful in libraries)");
	print_html("<strong>limited</strong>: allow limited buffs");
	print_html("<strong>sim</strong>: simulate what would happen, and what it might cost");
	print_html("");
	print_html("Example usage:");
	print_html("<strong>gain 400 initiative</strong>: buff to 400 initiative, as efficiently as possible");
	print_html("<strong>gain 20 familiar weight 50 turns</strong>: buff to 20 familiar weight, for a minimum of 50 turns");
	print_html("<strong>gain 400 init 20 familiar weight 300 muscle 50 turns</strong>: buff familiar weight up to 20, initiative up to 400, and muscle up to 300, for 50 turns.");
	print_html("<strong>gain 10000 monster level 10000 maxmeatspent</strong>: spend 10k meat on +monster level");
	print_html("<strong>gain meat 1 eff</strong>: gain meat with a certain efficiency level");
}

string ModifierConvertUserModifierToMafia(string modifier_name)
{
	modifier_name = modifier_name.to_lower_case();
	if (modifier_name == "init") return "initiative";
	if (modifier_name == "item") return "item drop";
	if (modifier_name == "meat") return "meat drop";
	if (modifier_name == "mus") return "muscle";
	if (modifier_name == "mys") return "mysticality";
	if (modifier_name == "myst") return "mysticality";
	if (modifier_name == "mox") return "moxie";
	if (modifier_name == "da") return "damage absorption";
	if (modifier_name == "dr") return "damage reduction";
	if (modifier_name == "mp") return "maximum mp";
	if (modifier_name == "hp") return "maximum hp";
	if (modifier_name == "ml") return "monster level";
	if (modifier_name == "combat") return "combat rate";
	if (modifier_name == "cold res") return "cold resistance";
	if (modifier_name == "hot res") return "hot resistance";
	if (modifier_name == "sleaze res") return "sleaze resistance";
	if (modifier_name == "stench res") return "stench resistance";
	if (modifier_name == "spooky res") return "spooky resistance";
	if (modifier_name == "mainstat") return my_primestat().to_string();
	if (modifier_name.contains_text("dmg")) return replace_string(modifier_name, "dmg", "damage");
	return modifier_name;
}


void ModifierAddUserModifier(int [string] desired_modifiers, string current_modifier, int modifier_value)
{
	if (modifier_value == 0.0)
	{
		modifier_value = 1000000.0;
	}
	string converted_modifier = ModifierConvertUserModifierToMafia(current_modifier);
	if (converted_modifier == "all res")
	{
		foreach s in $strings[cold resistance,hot resistance,sleaze resistance,stench resistance,spooky resistance]
			desired_modifiers[s] = modifier_value;
	}
	else
		desired_modifiers[converted_modifier] = modifier_value;
}

void main(string arguments)
{
	__starting_meat = my_meat();
	if (arguments == "" || arguments.contains_text("help"))
	{
		ModifierOutputExampleUsage();
		return;
	}
	
	int [string] desired_modifiers;
	int desired_min_turns = 1;
	
	
	float maximum_efficiency = 0.0;
	boolean maximum_efficiency_known = false;
	int modifier_value = 0;
	string current_modifier;
	string [int] arguments_split = arguments.split_string(" ");
	foreach key, argument in arguments_split
	{
		if (argument == "") continue;
		boolean ignore_text = false;
		if (argument == "sim")
		{
			__setting_simulation_only = true;
			continue;
		}
		if (argument == "turns" || argument == "turn")
		{
			desired_min_turns = MAX(1, modifier_value);
			modifier_value = 0;
			ignore_text = true;
		}
		if (argument == "eff" || argument == "efficiency")
		{
			maximum_efficiency_known = true;
			maximum_efficiency = modifier_value;
			modifier_value = 0.0;
			ignore_text = true;
		}
		if (argument == "absolute" || argument == "nopercentage")
		{
			__setting_ignore_percentages = true;
			ignore_text = true;
		}
		if (argument == "limited")
		{
			__setting_allow_limited_buffs = true;
			ignore_text = true;
		}
		if (argument == "silent")
		{
			__setting_silent = true;
			ignore_text = true;
		}
		if (argument == "maxmeatspent")
		{
			__maximum_meat_to_spend = modifier_value;
			modifier_value = 0.0;
			ignore_text = true;
		}
		if (is_integer(argument))
		{
			if (current_modifier != "")
			{
				ModifierAddUserModifier(desired_modifiers, current_modifier, modifier_value);
				current_modifier = "";
			}
			modifier_value = argument.to_int();
		}
		else if (ignore_text)
		{
			current_modifier = "";
		}
		else
		{
			if (current_modifier != "")
				current_modifier += " ";
			current_modifier += argument;
		}
	}
	blockLimitedBuffs();
	if (!__setting_silent)
		print_html("Gain v" + __gain_version);
	if (!__setting_silent)
		print_html("Spending up to " + __maximum_meat_to_spend + " meat.");
	if (maximum_efficiency_known && !__setting_silent)
		print_html(maximum_efficiency + " efficiency");
	if (current_modifier != "")
	{
		ModifierAddUserModifier(desired_modifiers, current_modifier, modifier_value);
		current_modifier = "";
	}
	
	if (!can_interact() && !__setting_silent)
	{
		print_html("We're not in ronin, so we might break. I didn't test for this.");
	}
	
	if (desired_modifiers.count() == 0 && !__setting_silent)
	{
		print_html("Did not recognise \"" + arguments + "\".");
		ModifierOutputExampleUsage();
		return;
	}
	if (!__setting_silent)
	{
		buffer output_string;
		output_string.append("Buffing ");
		boolean first = true;
		foreach modifier_name, value in desired_modifiers
		{
			if (first)
				first = false;
			else
				output_string.append(", ");
			output_string.append(modifier_name);
			output_string.append(" up to ");
			output_string.append(value);
		}
		if (desired_min_turns != 1)
		{
			output_string.append(", for ");
			output_string.append(desired_min_turns);
			output_string.append(" turns");
		}
		output_string.append("...");
		print_html(output_string);
	}
	
	foreach modifier_name, minimum in desired_modifiers
	{
		ModifierUpkeepSettings modifier_settings;
		modifier_settings.modifier_name = modifier_name;
		modifier_settings.minimum_value = minimum;
		modifier_settings.minimum_turns_wanted = desired_min_turns;
		modifier_settings.reasonable_turns_wanted = MAX(desired_min_turns, min(my_adventures(), 20));
		modifier_settings.maximum_efficiency_set = maximum_efficiency_known;
		modifier_settings.maximum_efficiency = maximum_efficiency;
		ModifierUpkeepEffects(modifier_settings);
	}

	if (__setting_simulation_only)
	{
		print_html("<\br>Execute:");
		print(__simulation_output);
		print("===========");
		print_html("Estimated cost: " + __meat_spent + " meat  (" + __meat_spent/desired_min_turns + "/turn )");
		print_html("Estimated turns gained range from [" + __simulation_effect_min_turns +" min to " + __simulation_effect_max_turns + " max]");
	}
	
}
