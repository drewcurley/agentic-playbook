### This file contains all functions pertaining to the player character and a few more###
import random
import time
from monsters import monster_actions_in_combat, monster_melee_attack, monster_doge_action
import json
import os


def starting_stats():
    stat_dict = {
        "MHP": 12,
        "CHP": 12,
        "MSP": 5,
        "CSP": 5, 
        "MMP": 5,
        "CMP": 5,
        "PL": 1,
        "GP": 25,
        "AP": 1,
        "DP": 10,
        "EW": "",
        "EA": "RIPPED CLOTH"
    }
    return stat_dict



def starting_inventory():
    """Weapon stats [gold value, attack power]
    Armor stats [gold value, defense power]
    trinket stats [gold value, amount in iventory]"""
    
    inventory_dict = {
        "Weapons":{},
        "Armors" :{"RIPPED CLOTH": [0, 10]},
        "Trinkets" :{},
    }
    return inventory_dict



def starting_spells():
    """Spell stats: [cost, power]"""

    spell_dict = {
        "BASIC MAGIC MISSILE": [2 , 2],
        "BASIC HEALING": [5 , 4],
    }

    return spell_dict



def leveling_up(stat_dict={"PL": 0}):
    """Increases the player's lvl"""

    if stat_dict["PL"] < 1:
        new_stat_dict = starting_stats()
    else:
        stat_dict["PL"] += 1
        slow_print(f"You've leveled up to lvl: {stat_dict["PL"]}")
        new_stat_dict = upgrade_stats(stat_dict)
        stat_dict["CHP"] = stat_dict["MHP"]
        stat_dict["CSP"] = stat_dict["MSP"]
        stat_dict["CMP"] = stat_dict["MMP"]

    return new_stat_dict



def upgrade_stats(stat_dict):
    """Upgrades one stat of choice by 2 points"""

    lvl_up_choice = input("Do you want to increase your HP, SP, or MP by 2 points? ").upper()
    incorrect_input_counter = 0
    while incorrect_input_counter < 2:

        if lvl_up_choice != "HP" and lvl_up_choice != "SP" and lvl_up_choice != "MP":
            lvl_up_choice = input("Invaild Input, please try again. ").upper()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if incorrect_input_counter == 2:
        lvl_up_choice = "HP"
    
    if lvl_up_choice == "HP":
        stat_dict["MHP"] += 2
    elif lvl_up_choice == "SP":
        stat_dict["MSP"] += 2
    else:
        stat_dict["MMP"] += 2

    return stat_dict



def charcter_creator():
    """System for creating the character having them choose a name and class."""
    stat_dict = leveling_up()

    print()
    stat_dict["Name"] = input('''"Tell me, what do you call yourself Void Spawn?" ''')
    print()

    class_option = input('''"And What role do you profess? Are you, a KNIGHT, a THIEF, or a MAGE?" ''').upper()
    print()

    incorrect_input_counter = 0

    while incorrect_input_counter < 2:

        if class_option != "KNIGHT" and class_option != "THIEF" and class_option != "MAGE":
            class_option = input("Invaild input, please try again. ").upper()
            print()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if class_option != "KNIGHT" and class_option != "THIEF" and class_option != "MAGE":
        incorrect_input_counter += 1

    if incorrect_input_counter == 3:
        slow_print('''"Ahh not much of the talking type are you. Must be a KNIGHT."\n''')
        class_option = "KNIGHT"

    if class_option == "KNIGHT":
        stat_dict["Class"] = "KNIGHT"
        stat_dict["MSP"] += 5
        stat_dict["CSP"] = stat_dict["MSP"]
    elif class_option == "THIEF":
        stat_dict["Class"] = "THIEF"
        stat_dict["MSP"] += 3
        stat_dict["MMP"] += 2
        stat_dict["CSP"] = stat_dict["MSP"]
        stat_dict["CMP"] = stat_dict["MMP"]
    else:
        stat_dict["Class"] = "MAGE"
        stat_dict["MMP"] += 5
        stat_dict["CMP"] = stat_dict["MMP"]

    return stat_dict



def veiw_character_sheet(stat_dict, inventory_dict, spell_dict):
    """Allows player to view thier stats"""
    print()
    print(f"Name: {stat_dict["Name"]}")
    print(f"Class: {stat_dict["Class"]}| Player Level: {stat_dict["PL"]}| Gold: {stat_dict["GP"]}")
    print(f"""Hit Points: {stat_dict["CHP"]}/{stat_dict["MHP"]}| Stamina: {stat_dict["CSP"]}/{stat_dict["MSP"]}| Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}""")
    print(f"Attack Power: {stat_dict["AP"]}| Defensive Power: {stat_dict["DP"]}")
    print("Inventory:")
    print("    Weapons:")

    for key in inventory_dict["Weapons"]:
        print()
        print("         ", key, "| Attack Power: ", inventory_dict["Weapons"][key][1])
    print()

    print("    Armors:")

    for key in inventory_dict["Armors"]:
        print("         ", key, "| Defense: ", inventory_dict["Armors"][key][1])
    print()

    print("    Trinkets:")

    for key in inventory_dict["Trinkets"]:
        print("         ", inventory_dict["Trinkets"][key][1] , key)

    print()
    print("Spells Known:")
    for key in spell_dict:
        print( "    " , key, " | Power:", spell_dict[key][1], " | Cost:", spell_dict[key][0])
    
    print()
    print()
    input("[Press enter when you wish to continue.] ")
    clear_screen()
    pass



def add_weapon_to_inventory(inventory_dict, weapon_list):
    """weapon list format [name, gold value, attack power]"""
    weapon_name = weapon_list[0]
    weapon_value = weapon_list[1]
    weapon_power = weapon_list[2]

    inventory_dict["Weapons"][weapon_name] = [weapon_value, weapon_power]
    slow_print(f"{weapon_name} has been added to your inventory.")
    time.sleep(2)
    return inventory_dict



def add_armor_to_inventory(inventory_dict, armor_list):
    """Armor list format [name, gold value, defense power]"""
    armor_name = armor_list[0]
    armor_value = armor_list[1]
    armor_power = armor_list[2]

    inventory_dict["Armors"][armor_name] = [armor_value, armor_power]
    slow_print(f"{armor_name} has been added to your inventory.")
    time.sleep(2) 
    return inventory_dict



def add_trinket_to_inventory(inventory_dict, trinket_list):
    """weapon list format [name, gold value, qaunity]"""
    trinket_name = trinket_list[0]
    trinket_value = trinket_list[1]
    trinket_quanity = trinket_list[2]

    if trinket_name in inventory_dict["Trinkets"]:
        inventory_dict["Trinkets"][trinket_name][1] += trinket_quanity
    else:
        inventory_dict["Trinkets"][trinket_name] = [trinket_value, trinket_quanity]
    
    if trinket_quanity == 1:
        slow_print(f"{trinket_quanity} {trinket_name} has been added to your inventory.")
    else:
        slow_print(f"{trinket_quanity} {trinket_name}s have been added to your inventory.")
    time.sleep(2)
    return inventory_dict



def equipt_weapon(inventory_dict, stat_dict):
    """Allows players to choose which weapon to use"""
    counter = 0
    print()
    print("Weapons:")

    for key in inventory_dict["Weapons"]:
        counter += 1
        print(counter,": ", key, " Attack Power:", inventory_dict["Weapons"][key][1])
    
    key_options = list(inventory_dict["Weapons"].keys()) # makes list of keys to give use option to enter numbers instead of full names

    equipt_choice = input("Which weapon do you want to equipt? ").upper()
    incorrect_input_counter = 0
    while incorrect_input_counter < 2:

        if equipt_choice not in inventory_dict["Weapons"]:

            try:
                index = int(equipt_choice)
                
                if index <= counter and index > 0:
                    index -= 1
                    equipt_choice = key_options[index]
                    incorrect_input_counter = 5
                else:
                    equipt_choice = input("incorrect input, please enter the weapon's name as shown above. ").upper()
                    incorrect_input_counter += 1

            except ValueError:
                equipt_choice = input("incorrect input, please enter the weapon's name as shown above. ").upper()
                incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if equipt_choice not in inventory_dict["Weapons"]:
        try:
            index = int(equipt_choice)
                
            if index <= counter and index > 0:
                index -= 1
                equipt_choice = key_options[index]
            else:
                incorrect_input_counter += 1

        except ValueError:
            incorrect_input_counter += 1

    if incorrect_input_counter == 3:
        equipt_choice = key_options[0]
    
    weapon_stats = inventory_dict["Weapons"][equipt_choice]
    attack_power = weapon_stats[1]
    stat_dict["AP"] = attack_power
    stat_dict["EW"] = equipt_choice

    slow_print(f"\n{equipt_choice} has been equipped.\n")
    time.sleep(2)
    return stat_dict



def equipt_armor(inventory_dict, stat_dict):
    """Allows players to choose which armor set to use"""
    counter = 0
    print()
    print("Armors:")

    for key in inventory_dict["Armors"]:
        counter += 1
        print(counter,": ", key, " Defensive Power:", inventory_dict["Armors"][key][1])

    key_options = list(inventory_dict["Armors"].keys())

    equipt_choice = input("Which armor do you want to equipt? ").upper()
    incorrect_input_counter = 0
    while incorrect_input_counter < 2:

        if equipt_choice not in inventory_dict["Armors"]:
            try:
                index = int(equipt_choice)
                
                if index <= counter and index > 0:
                    index -= 1
                    equipt_choice = key_options[index]
                    incorrect_input_counter = 5
                else:
                    equipt_choice = input("incorrect input, please enter the Armor's name as shown above. ").upper()
                    incorrect_input_counter += 1

            except ValueError:
                equipt_choice = input("incorrect input, please enter the Armor's name as shown above. ").upper()
                incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if equipt_choice not in inventory_dict["Armors"]:
        try:
            index = int(equipt_choice)
                
            if index <= counter and index > 0:
                index -= 1
                equipt_choice = key_options[index]
            else:
                incorrect_input_counter += 1

        except ValueError:
            incorrect_input_counter += 1

    if incorrect_input_counter == 3:
        equipt_choice = "RIPPED CLOTH"
    
    armor_stats = inventory_dict["Armors"][equipt_choice]
    defensive_power = armor_stats[1]
    stat_dict["DP"] = defensive_power
    stat_dict["EA"] = equipt_choice

    slow_print(f"\n{equipt_choice} has been equipped.\n")
    time.sleep(2)
    return stat_dict



def melee_attack(stat_dict, monster_stat_dict):
    """The player makes a basic attack, with chance to hit, miss, or score a critical hit."""
    if stat_dict["CSP"] >= 1:
        stat_dict["CSP"] -= 1
    
        attack_power = stat_dict["AP"]
        monster_defensive_power = monster_stat_dict["DP"]

        roll_to_hit = random.randint(1, 100)
        if roll_to_hit >= 95:
            attack_power *= 2
            print("!!Critical Hit!!")

        if roll_to_hit > monster_defensive_power:
            monster_stat_dict["HP"] -= attack_power

            if monster_stat_dict["HP"] > 0:
                slow_print(f"You hit the {monster_stat_dict["Name"]} for {attack_power} point/s of damage.", 0.01)
            else:
                slow_print(f"You killed the {monster_stat_dict["Name"]}! The finishing blow dealt {attack_power} point/s of damage!", 0.01)
        else:
            slow_print("Your attack missed.", 0.01)
    else:
        slow_print("Your Attack failed, you don't have enought stamina.", 0.01)
    
    time.sleep(1)
    return stat_dict, monster_stat_dict



def basic_magic_missile(monster_stat_dict):
    """players casts a spell which never misses it's target."""
    attack_power = 2
    monster_stat_dict["HP"] -= attack_power

    if monster_stat_dict["HP"] > 0:
            slow_print(f"You hit the {monster_stat_dict["Name"]} for {attack_power} point/s of damage.", 0.01)
    else:
            slow_print(f"You killed the {monster_stat_dict["Name"]}! The finishing blow dealt {attack_power} point/s of damage!", 0.01)

    time.sleep(1)
    return monster_stat_dict



def actions_in_combat(stat_dict, spell_dict, monster_stat_dict, inventory_dict):
    '''allows player to choose what they do on their turn during combat'''
    print()
    print(stat_dict["Name"])
    print(f"""Hit Points: {stat_dict["CHP"]}/{stat_dict["MHP"]}| Stamina: {stat_dict["CSP"]}/{stat_dict["MSP"]}| Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}""")
    print("What do you do on your turn?")
    print("1: ATTACK with your weapon?")
    print("2: CAST a spell?")
    print("3: USE a Trinket?")

    combat_choice = input().upper()

    incorrect_input_counter = 0
    while incorrect_input_counter < 2:
        if combat_choice != "ATTACK" and combat_choice != "CAST" and combat_choice != "USE" and combat_choice != "1" and combat_choice !="2" and combat_choice != "3":
            combat_choice = input("Invaild input, please try again ").upper()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5

    if combat_choice != "ATTACK" and combat_choice != "CAST" and combat_choice != "USE" and combat_choice != "1" and combat_choice !="2" and combat_choice != "3":
        combat_choice = "ATTACK"
    
    
    if combat_choice == "ATTACK" or combat_choice == "1":
        mixed_dict = melee_attack(stat_dict, monster_stat_dict)
        stat_dict = mixed_dict[0]
        monster_stat_dict = mixed_dict[1]
    elif combat_choice == "CAST" or combat_choice == "2":
        mixed_dict = casting_spells_in_combat(stat_dict, spell_dict, monster_stat_dict)
        stat_dict = mixed_dict[0]
        monster_stat_dict = mixed_dict[1]
    elif combat_choice == "USE"or combat_choice == "3":
        mixed_dict = use_trinket_in_combat(stat_dict,monster_stat_dict, inventory_dict)
        stat_dict = mixed_dict[0]
        monster_stat_dict = mixed_dict[1]
        inventory_dict = mixed_dict[2]


    time.sleep(2)
    return stat_dict, monster_stat_dict, inventory_dict



def casting_spells_in_combat(stat_dict,spell_dict, monster_stat_dict={}):
    '''allows player to choose which spell to cast during combat'''
    counter = 0
    print()
    print("Spells:")

    lowest_spell_cost = 999

    for key in spell_dict:
        counter += 1
        print(counter,": ", key, " | Power:", spell_dict[key][1], " | Cost:", spell_dict[key][0])

        spell_cost = spell_dict[key][0]

        if spell_cost < lowest_spell_cost:
            lowest_spell_cost = spell_cost


    if stat_dict["CMP"] >= lowest_spell_cost:
        key_options = list(spell_dict.keys())

        spell_choice = input("Which spell would you liked to cast? ").upper()

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:

            if spell_choice not in spell_dict:
                try:
                    index = int(spell_choice)
                
                    if index <= counter and index > 0:
                        index -= 1
                        spell_choice = key_options[index]
                        incorrect_input_counter = 5
                    else:
                        spell_choice = input("incorrect input, please enter the spell's name as shown above. ").upper()
                        incorrect_input_counter += 1

                except ValueError:
                    spell_choice = input("incorrect input, please enter the spell's name as shown above. ").upper()
                    incorrect_input_counter += 1

            else:
                incorrect_input_counter = 5
    
        if spell_choice not in spell_dict:
            try:
                index = int(spell_choice)
                
                if index <= counter and index > 0:
                    index -= 1
                    spell_choice = key_options[index]
                else:
                    incorrect_input_counter += 1

            except ValueError:
                incorrect_input_counter += 1

        if incorrect_input_counter == 3:
            spell_choice = "BASIC MAGIC MISSILE"
            slow_print("You cast BASIC MAGIC MISSILE by default.", 0.01)
            time.sleep(2)
    
        if spell_choice == "BASIC MAGIC MISSILE":
            if stat_dict["CMP"] >= 2:
                stat_dict["CMP"] -= 2
                monster_stat_dict = basic_magic_missile(monster_stat_dict)
            else:
                slow_print("The spell failed, you didn't have enought mana.", 0.01)
                time.sleep(2)
        elif spell_choice == "BASIC HEALING":
            if stat_dict["CMP"] >= 5:
                stat_dict["CMP"] -= 5
                stat_dict = basic_healing(stat_dict)
            else:
                slow_print("The spell failed, you didn't have enought mana.", 0.01)
                time.sleep(2)
        # add more spells later

    else:
        slow_print("You don't have enough mana to cast any spells.", 0.01)
        time.sleep(2)

    return stat_dict,monster_stat_dict 



def basic_healing(stat_dict):
    '''the play can cast a baisc healing spell to heal themselves by 4 points'''

    before_healing = stat_dict["CHP"]

    stat_dict["CHP"] += 4
    if stat_dict["CHP"] > stat_dict["MHP"]:
        stat_dict["CHP"] = stat_dict["MHP"]
    
    after_healing = stat_dict["CHP"]

    amount_healed = after_healing - before_healing
    slow_print(f"You've been healed for {amount_healed} points!", 0.01)
    time.sleep(1.5)
    return stat_dict



def combat(stat_dict, inventory_dict ,spell_dict, monster_stats):
    '''this function runs combat, it allows for random chance of who goes first'''
    print()
    print("-" * 90)
    time.sleep(.5)

    monster_stat_dict = monster_stats()

    pre_combat_stat_dict = stat_dict.copy()
    pre_combat_Monster_stat_dict = monster_stat_dict.copy()

    player_initiative = random.randint(1, 100) + stat_dict["CSP"]
    monster_initiative = random.randint(1,100) + monster_stat_dict["AP"]

    monster_effecting_player = False
    player_effecting_monster = False

    while stat_dict["CHP"] > 0 and monster_stat_dict["HP"] > 0:

        if player_initiative > monster_initiative:
            mixed_dict = players_turn(stat_dict, spell_dict, monster_stat_dict, pre_combat_stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            monster_stat_dict = mixed_dict[1]
            inventory_dict = mixed_dict [2]

            clear_screen()
            if monster_stat_dict["HP"] > 0:
                mixed_dict = monsters_turn(stat_dict, monster_stat_dict, pre_combat_stat_dict ,pre_combat_Monster_stat_dict, monster_effecting_player)
                stat_dict = mixed_dict[0]
                monster_stat_dict = mixed_dict[1]
                monster_effecting_player = mixed_dict[2]
        else:
            clear_screen()
            mixed_dict = monsters_turn(stat_dict, monster_stat_dict, pre_combat_stat_dict, pre_combat_Monster_stat_dict, monster_effecting_player)
            stat_dict = mixed_dict[0]
            monster_stat_dict = mixed_dict[1]
            monster_effecting_player = mixed_dict[2]

            if stat_dict["CHP"] > 0:
                mixed_dict = players_turn(stat_dict, spell_dict, monster_stat_dict, pre_combat_stat_dict, inventory_dict)
                stat_dict = mixed_dict[0]
                monster_stat_dict = mixed_dict[1]
                inventory_dict = mixed_dict [2]

    if monster_stat_dict["HP"] <= 0:
        stat_dict["GP"] += monster_stat_dict["GP"]

        stat_dict["MHP"] = pre_combat_stat_dict["MHP"]
        stat_dict["MSP"] = pre_combat_stat_dict["MSP"]
        stat_dict["MMP"] = pre_combat_stat_dict["MMP"]
        stat_dict["AP"] = pre_combat_stat_dict["AP"]
        stat_dict["DP"] = pre_combat_stat_dict["DP"]

    clear_screen()
    return stat_dict, inventory_dict



def players_turn(stat_dict, spell_dict, monster_stat_dict, pre_combat_stat_dict, inventory_dict):
    """On player's turn, will choose an action to preform. I have more planed for this function but I 
will add those later on my own time as they were not within the scope of this project."""

    mixed_dict = actions_in_combat(stat_dict, spell_dict, monster_stat_dict, inventory_dict)
    return mixed_dict



def monsters_turn(stat_dict, monster_stat_dict, pre_combat_stat_dict ,pre_combat_Monster_stat_dict, monster_effecting_player):
    """On the monsterr's turn, system will reset the following stats, Max hit points, Max stamina, Max Mana, Attack Power, Defensive power"""
    monster_stat_dict["AP"] = pre_combat_Monster_stat_dict["AP"]
    monster_stat_dict["DP"] = pre_combat_Monster_stat_dict["DP"]

    if monster_effecting_player == True:
        stat_dict["MHP"] = pre_combat_stat_dict["MHP"]
        stat_dict["MSP"] = pre_combat_stat_dict["MSP"]
        stat_dict["MMP"] = pre_combat_stat_dict["MMP"]
        stat_dict["AP"] = pre_combat_stat_dict["AP"]
        stat_dict["DP"] = pre_combat_stat_dict["DP"]

    mixed_dict = monster_actions_in_combat(stat_dict, monster_stat_dict, monster_effecting_player)
    return mixed_dict



def use_trinket_in_combat(stat_dict, monster_stat_dict, inventory_dict):
    '''allows player to use items they have picked up on their journey, in combat.'''
    counter = 0
    print()
    print("Trinkets:")

    for key in inventory_dict["Trinkets"]:
        counter +=1
        print(counter,": ", key, " | Value:", inventory_dict["Trinkets"][key][0], " | Quanity:", inventory_dict["Trinkets"][key][1])

    if counter > 0:
        trinket_choice = input("Which trinket would you liked to use? ").upper()

        key_options = list(inventory_dict["Trinkets"].keys())

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:

            if trinket_choice not in inventory_dict["Trinkets"]:

                try:
                    index = int(trinket_choice)
                    if index <= counter and index > 0:
                        index -= 1
                        trinket_choice = key_options[index]
                        incorrect_input_counter = 5
                    else:
                        trinket_choice = input("incorrect input, please enter the trinket's name as shown above. ").upper()
                        incorrect_input_counter += 1
                
                except ValueError:
                    trinket_choice = input("incorrect input, please enter the trinket's name as shown above. ").upper()
                    incorrect_input_counter += 1
            else:
                incorrect_input_counter = 5
    

        if trinket_choice not in inventory_dict["Trinkets"]:
            try:
                index = int(trinket_choice)
                if index <= counter and index > 0:
                    index -= 1
                    trinket_choice = key_options[index]
                else:
                    incorrect_input_counter += 1
                
            except ValueError:
                incorrect_input_counter += 1

        if incorrect_input_counter == 3:
            trinket_choice = None
            slow_print("You fumbled to grab and use a Trinket, how sad.", 0.01)
            time.sleep(2)
    
        if trinket_choice == "TINY HEALING POTION":
            mixed_dict = using_tiny_healing_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

        elif trinket_choice == "TINY STAMINA POTION":
            mixed_dict = using_tiny_stamina_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
        
        elif trinket_choice == "TINY MANA POTION":
            mixed_dict = using_tiny_mana_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
    else:
        slow_print("Looks like you have no trinkets left...", 0.01)
        time.sleep(2)

    time.sleep(1)
    return stat_dict, monster_stat_dict, inventory_dict



def using_tiny_healing_potion(stat_dict, inventory_dict):
    '''heals player when used by 2-4 points'''
    before_healing = stat_dict["CHP"]

    stat_dict["CHP"] += random.randint(2,4)
    if stat_dict["CHP"] > stat_dict["MHP"]:
        stat_dict["CHP"] = stat_dict["MHP"]
    
    after_healing = stat_dict["CHP"]

    amount_healed = after_healing - before_healing
    slow_print(f"You've been healed for {amount_healed} points!")
    time.sleep(0.5)

    inventory_dict["Trinkets"]["TINY HEALING POTION"][1] -= 1

    if inventory_dict["Trinkets"]["TINY HEALING POTION"][1] == 0:
        inventory_dict["Trinkets"].pop("TINY HEALING POTION")

    time.sleep(1)
    return stat_dict, inventory_dict



def using_tiny_stamina_potion(stat_dict, inventory_dict):
    '''restores player's stamina when used by 2-4 points'''
    before_healing = stat_dict["CSP"]

    stat_dict["CSP"] += random.randint(2,4)
    if stat_dict["CSP"] > stat_dict["MSP"]:
        stat_dict["CSP"] = stat_dict["MSP"]
    
    after_healing = stat_dict["CSP"]

    amount_healed = after_healing - before_healing
    slow_print(f"Your stamina has been restored by {amount_healed} points!")
    time.sleep(0.5)

    inventory_dict["Trinkets"]["TINY STAMINA POTION"][1] -= 1

    if inventory_dict["Trinkets"]["TINY STAMINA POTION"][1] == 0:
        inventory_dict["Trinkets"].pop("TINY STAMINA POTION")

    time.sleep(1)
    return stat_dict, inventory_dict



def using_tiny_mana_potion(stat_dict, inventory_dict):
    '''restores player's mana when used by 2-4 points'''
    before_healing = stat_dict["CMP"]

    stat_dict["CMP"] += random.randint(2,4)
    if stat_dict["CMP"] > stat_dict["MMP"]:
        stat_dict["CMP"] = stat_dict["MMP"]
    
    after_healing = stat_dict["CMP"]

    amount_healed = after_healing - before_healing
    slow_print(f"Your mana has been restored by {amount_healed} points!")
    time.sleep(0.5)

    inventory_dict["Trinkets"]["TINY MANA POTION"][1] -= 1

    if inventory_dict["Trinkets"]["TINY MANA POTION"][1] == 0:
        inventory_dict["Trinkets"].pop("TINY MANA POTION")

    time.sleep(1)
    return stat_dict, inventory_dict



def actions_while_exploring(inventory_dict, additonal_options_list=[]):
    '''allows player to choose an action while exploring dungeons.'''
    options_list = ["SEARCH", "NAVIGATE", "CAST", "USE", "VIEW", "EQUIPT WEAPON", "EQUIPT ARMOR"]
    counter = 0

    
    for i in additonal_options_list:
        options_list.append(i)

    print()
    print("What would you like to do?")
    for i in options_list:
        counter += 1
        print(f" {counter}: {i}")

    action_choice = input().upper()

    incorrect_input_counter = 0
    while incorrect_input_counter < 2:

        if action_choice not in options_list:

            try:
                index = int(action_choice)
                if index <= counter and index > 0:
                    index -= 1
                    action_choice = options_list[index]
                    incorrect_input_counter = 5
                else:
                    action_choice = input("incorrect input, please enter which option you would like as shown above. ").upper()
                    incorrect_input_counter += 1
                
            except ValueError:
                action_choice = input("incorrect input, please enter which option you would like as shown above. ").upper()
                incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5

    if action_choice not in options_list:
        try:
            index = int(action_choice)
            if index <= counter and index > 0:
                index -= 1
                action_choice = options_list[index]
            else:
                action_choice = None
                
        except ValueError:
            action_choice = None

    if action_choice == "2":
        action_choice = "NAVIGATE"

    return action_choice



def combat_spell_out_of_combat():
    slow_print("\nThe spell failed because there is no vaild target available.", 0.01)
    time.sleep(2)
    pass



def casting_spells_outside_combat(stat_dict, spell_dict):
    '''allows player to cast spells out of combat. Some spells will have different effects when cast in or out of combat'''
    counter = 0
    print()
    print(f"Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}")
    print("Spells:")

    lowest_spell_cost = 999

    for key in spell_dict:
        counter += 1
        print(counter,": ", key, " | Power:", spell_dict[key][1], " | Cost:", spell_dict[key][0])

        spell_cost = spell_dict[key][0]

        if spell_cost < lowest_spell_cost:
            lowest_spell_cost = spell_cost


    if stat_dict["CMP"] >= lowest_spell_cost:
        key_options = list(spell_dict.keys())

        spell_choice = input("Which spell would you liked to cast? ").upper()

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:

            if spell_choice not in spell_dict:
                try:
                    index = int(spell_choice)
                
                    if index <= counter and index > 0:
                        index -= 1
                        spell_choice = key_options[index]
                        incorrect_input_counter = 5
                    else:
                        spell_choice = input("incorrect input, please enter the spell's name as shown above. ").upper()
                        incorrect_input_counter += 1

                except ValueError:
                    spell_choice = input("incorrect input, please enter the spell's name as shown above. ").upper()
                    incorrect_input_counter += 1

            else:
                incorrect_input_counter = 5
    
        if spell_choice not in spell_dict:
            try:
                index = int(spell_choice)
                
                if index <= counter and index > 0:
                    index -= 1
                    spell_choice = key_options[index]
                else:
                    incorrect_input_counter += 1

            except ValueError:
                incorrect_input_counter += 1

        if incorrect_input_counter == 3:
            spell_choice = "BASIC MAGIC MISSILE"
            slow_print("You cast BASIC MAGIC MISSILE by default.", 0.01)
            time.sleep(2)
    
        if spell_choice == "BASIC MAGIC MISSILE":
            if stat_dict["CMP"] >= 2:
                stat_dict["CMP"] -= 2
                combat_spell_out_of_combat()
            else:
                slow_print("The spell failed, you didn't have enought mana.", 0.01)
                time.sleep(2)
        elif spell_choice == "BASIC HEALING":
            if stat_dict["CMP"] >= 5:
                stat_dict["CMP"] -= 5
                stat_dict = basic_healing(stat_dict)
            else:
                slow_print("The spell failed, you didn't have enought mana." , 0.01)
                time.sleep(2)
        # add more spells later

    else:
        slow_print("You don't have enough mana to cast any spells.", 0.01)
        time.sleep(2)

    return stat_dict



def using_trinket_outside_combat(stat_dict, inventory_dict):
    '''allows player to use trinkets outside of combat, some items have different uses in and out of combat'''
    counter = 0
    print()
    print("Trinkets:")

    for key in inventory_dict["Trinkets"]:
        counter +=1
        print(counter,": ", key, " | Value:", inventory_dict["Trinkets"][key][0], " | Quanity:", inventory_dict["Trinkets"][key][1])

    if counter > 0:
        trinket_choice = input("Which trinket would you liked to use? ").upper()

        key_options = list(inventory_dict["Trinkets"].keys())

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:

            if trinket_choice not in inventory_dict["Trinkets"]:

                try:
                    index = int(trinket_choice)
                    if index <= counter and index > 0:
                        index -= 1
                        trinket_choice = key_options[index]
                        incorrect_input_counter = 5
                    else:
                        trinket_choice = input("incorrect input, please enter the trinket's name as shown above. ").upper()
                        incorrect_input_counter += 1
                
                except ValueError:
                    trinket_choice = input("incorrect input, please enter the trinket's name as shown above. ").upper()
                    incorrect_input_counter += 1
            else:
                incorrect_input_counter = 5
    

        if trinket_choice not in inventory_dict["Trinkets"]:
            try:
                index = int(trinket_choice)
                if index <= counter and index > 0:
                    index -= 1
                    trinket_choice = key_options[index]
                else:
                    incorrect_input_counter += 1
                
            except ValueError:
                incorrect_input_counter += 1

        if incorrect_input_counter == 3:
            trinket_choice = None
            slow_print("You fumbled to grab and use a Trinket, how sad.", 0.01)
            time.sleep(2)
    
        if trinket_choice == "TINY HEALING POTION":
            mixed_dict = using_tiny_healing_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

        elif trinket_choice == "TINY STAMINA POTION":
            mixed_dict = using_tiny_stamina_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
        
        elif trinket_choice == "TINY MANA POTION":
            mixed_dict = using_tiny_mana_potion(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
    else:
        slow_print("Looks like you have no trinkets left...", 0.01)
        time.sleep(2)
        trinket_choice = None

    return stat_dict, inventory_dict, trinket_choice



def using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, loot_table, has_searched_before, trinket_used=None, additonal_options_list=[]):
    '''takes the action choosen by player outside of combat and gives a result. allows for room specific actions and loot tables'''
    special_1 = False
    action_choice = actions_while_exploring(inventory_dict, additonal_options_list)
    

    if action_choice == "8" or action_choice == "SPECIAL 1":
        special_1 = True
        action_choice = "NAVIGATE"

    while action_choice != "NAVIGATE":

        if action_choice == "1" or action_choice == "SEARCH":
            mixed_dict = loot_table(stat_dict, inventory_dict, has_searched_before)
            stat_dict =  mixed_dict[0]
            inventory_dict = mixed_dict[1]
            has_searched_before = mixed_dict[2]

        elif action_choice == "3" or action_choice == "CAST":
            stat_dict = casting_spells_outside_combat(stat_dict, spell_dict)

        elif action_choice == "4" or action_choice == "USE":
            mixed_dict = using_trinket_outside_combat(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            trinket_used = mixed_dict[2]

        elif action_choice == "5" or action_choice == "VIEW":
            veiw_character_sheet(stat_dict, inventory_dict, spell_dict)

        elif action_choice == "6" or action_choice == "EQUIPT WEAPON":
            stat_dict = equipt_weapon(inventory_dict, stat_dict)
        
        elif action_choice == "7" or action_choice == "EQUIPT ARMOR":
            stat_dict = equipt_armor(inventory_dict, stat_dict)

        clear_screen()
        action_choice = actions_while_exploring(inventory_dict, additonal_options_list)

        if action_choice == "8" or action_choice == "SPECIAL 1":
            special_1 = True
            action_choice = "NAVIGATE"

    
    if special_1 == True:
        action_choice = "SPECIAL 1"

    return stat_dict, inventory_dict, has_searched_before, spell_dict, trinket_used, special_1, action_choice



def save_game(stat_dict, inventory_dict, spell_dict, checkpoint, filename="savefile1.txt"):
    '''saves the game onto a txt file'''

    save_data ={
        "stat_dict": stat_dict,
        "inventory_dict": inventory_dict,
        "spell_dict": spell_dict,
        "checkpoint": checkpoint 
    }

    with open(f"saves/{filename}.txt", "w") as file:
        json.dump(save_data, file)
    pass


    
def load_game(filename="savefile1.txt"):
    '''loads a game from a savefile'''

    with open(f"saves/{filename}.txt", "r") as file:
        raw_data = file.read()
        save_data = json.loads(raw_data)

    checkpoint = save_data["checkpoint"]
    stat_dict = save_data["stat_dict"]
    inventory_dict = save_data["inventory_dict"]
    spell_dict = save_data["spell_dict"]
    
    return stat_dict, inventory_dict, spell_dict, checkpoint



def clear_screen():
    '''clears the screen so it doesn't get cluttered'''
    os.system('cls' if os.name == 'nt' else 'clear')

def slow_print(text, delay=0.03):
    '''allows for a text scroll affect'''
    for char in text:
        print(char, end='', flush=True)
        time.sleep(delay)
    print()