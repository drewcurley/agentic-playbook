###This file contains all functions pretaining to the dungeons in the game and exploring them###
import time
import random
from character import charcter_creator, starting_inventory, starting_spells, add_weapon_to_inventory, equipt_weapon, basic_magic_missile, add_trinket_to_inventory, using_tiny_healing_potion, players_turn, monsters_turn, actions_while_exploring, casting_spells_outside_combat, using_trinket_outside_combat, veiw_character_sheet, using_actions_while_exporling
from story import yes_or_no_question, question_with_multiple_answers, multiple_answer_decider
from character import equipt_armor, combat, leveling_up, slow_print, clear_screen
from monsters import giant_rat_stats, giant_bat_stats, slime_stats, guardian_of_Zargonud



def tutorial_dungeon_the_ruined_prison(stat_dict, inventory_dict, spell_dict):
    '''The whole tutorial dungeon is within this function, every room of the dungeon lives here. this keeps track of where the player has been
    and if they've fullfilled the requirements to leave.'''
    print("\n" + "-" * 75)
    print("                         --The Ruined Prison-- ")
    print("-" * 75)
    time.sleep(2)
    slow_print("""Dropping down from the hole in the inner city wall, you land in the Ruined Prison, facing North.""")
    time.sleep(5)

    exit_key = False
    location = "ENTRANCE ROOM"
    visited_TDRP_CELLBLOCK = False
    visited_TDRP_guard_room = False
    ENTRANCE_ROOM_searched = False
    CELLBLOCK_searched = False
    trinket_used = None

    while exit_key == False:
        
        if location == "ENTRANCE ROOM":
            mixed_dict = TDRP_entrance_room(stat_dict, inventory_dict, spell_dict, ENTRANCE_ROOM_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            location = mixed_dict[2]
            ENTRANCE_ROOM_searched = mixed_dict[3]
            trinket_used = mixed_dict[4]

        elif location == "CELLBLOCK":
            mixed_dict = TDRP_cellbock(stat_dict, inventory_dict, spell_dict, visited_TDRP_CELLBLOCK, CELLBLOCK_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            location = mixed_dict[2]
            visited_TDRP_CELLBLOCK = mixed_dict[3]
            CELLBLOCK_searched = mixed_dict[4]

        elif location == "GUARD ROOM":
            mixed_dict = TDRP_guard_room(stat_dict, inventory_dict, spell_dict, visited_TDRP_guard_room)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            location = mixed_dict[2]
            visited_TDRP_guard_room = mixed_dict[3]

        elif location == "Exit":
            if trinket_used == "IRON KEY":
                exit_key = True
                inventory_dict["Trinkets"].pop("IRON KEY")

            elif "IRON KEY" in inventory_dict["Trinkets"]:
                exit_key = True
                inventory_dict["Trinkets"].pop("IRON KEY")

            elif trinket_used == "SILVER KEY":
                slow_print("\nThis key seems to be too small to interact with the lock, another key is needed. The door's lock is big and made of rusted IRON.")
            else:
                print("\nThe door to leave is locked. You need to find a key. The The door's lock is big and made of rusted IRON.")
            location = "ENTRANCE ROOM"

        elif location == "death":
            location = "Exit"
            exit_key = True
        
        clear_screen()
    
    slow_print("""\nYou place the heavy IRON KEY into the lock, it turns and 'Click!' the door swings open into a small courtyard where city guards had once
trained. The rain has stopped since you were within the prison, the setting sun peaks through the broken clouds.""")
    time.sleep(2)
    print('\n'+"-" * 75)
    print("                         --Dungeon Cleared-- ")
    print("-" * 75 +'\n')
    time.sleep(2)

    checkpoint = 2
    return stat_dict, inventory_dict, spell_dict, checkpoint



def TDRP_entrance_room(stat_dict, inventory_dict, spell_dict, has_searched_before):
    '''the first room of the tutorial dungeon'''
    slow_print("""\nFrom where you first entered, there are 3 doors ahead of you. One each to the East, West, and North of you. Besides that, the room is
pretty empty except for rubble, a few skeletons, and some very rusted shackles.\n""")
    time.sleep(1.5)

    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, has_searched_before)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]
    has_searched_before = mixed_dict[2]
    trinket_used = mixed_dict[4]

    location = question_with_multiple_answers("\nWhere do you go? \n1: East to CELLBLOCK \n2: West to GUARD ROOM \n3: North to EXIT","Where do you go? ", [
    "1", "2", "3", "N", "E", "W", "NORTH", "EAST", "WEST", "CELLBLOCK", "GUARD ROOM", "EXIT"])

    location = multiple_answer_decider(location, [["1","E", "EAST", "CELLBLOCK"],["2", "W", "WEST", "GUARD ROOM"], ["3", "N", "NORTH", "EXIT"]], ["CELLBLOCK", "GUARD ROOM", "Exit"])

    return stat_dict, inventory_dict, location, has_searched_before, trinket_used



def TDRP_cellbock(stat_dict, inventory_dict, spell_dict, visited_before, has_searched_before):
    
    if visited_before == False:
        slow_print(f"""\nIn this narrow corridor, there are 5 small cells of iron bars. These cells are in various states of repair. What looks like a giant
rat gnaws on the bones of a long dead prisoner. The rat catches your scent and turns to face you. Imprinted on the forehead of the giant rat is a bright
golden rune. The rat lunges towards you as you hold up your {stat_dict["EW"]} to defend yourself.\n""")
        time.sleep(3.25)

        clear_screen()
        mixed_dict = tutorial_combat(stat_dict, inventory_dict, spell_dict)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
    else:
        print("\nIn this narrow corridor, there are 5 small cells of iron bars. These cells are in various states of repair.")
    
    if stat_dict["CHP"] > 0:

        action_choice = actions_while_exploring(inventory_dict)

        while action_choice != "NAVIGATE":

            if action_choice == "1" or action_choice == "SEARCH":

                if has_searched_before == False:
                    print("\nYou search through the cells, the rumble and dust, finding only a small SILVER KEY engraved with an emblem of a sword.")
                    inventory_dict = add_trinket_to_inventory(inventory_dict, ["SILVER KEY", 0, 1])
                    time.sleep(3)
                    has_searched_before = True

                else:
                    print("\nYou find nothing of value")
                    time.sleep(1.5)

            elif action_choice == "3" or action_choice == "CAST":
                stat_dict = casting_spells_outside_combat(stat_dict, spell_dict)

            elif action_choice == "4" or action_choice == "USE":
                mixed_dict = using_trinket_outside_combat(stat_dict, inventory_dict)
                stat_dict = mixed_dict[0]
                inventory_dict = mixed_dict[1]

            elif action_choice == "5" or action_choice == "VIEW":
                clear_screen()
                veiw_character_sheet(stat_dict, inventory_dict, spell_dict)
            
            elif action_choice == "6" or action_choice == "EQUIPT WEAPON":
                stat_dict = equipt_weapon(inventory_dict, stat_dict)
        
            elif action_choice == "7" or action_choice == "EQUIPT ARMOR":
                stat_dict = equipt_armor(inventory_dict, stat_dict)

            clear_screen()
            action_choice = actions_while_exploring(inventory_dict)


        visited_before = have_you_visited_this_room_before(visited_before)
        location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
        if location == "Y" or location == "YES":
            location = "ENTRANCE ROOM"
        else:
            location = "CELLBLOCK"
    
    else: 
        location = "death"

    return stat_dict, inventory_dict, location, visited_before, has_searched_before



def TDRP_guard_room(stat_dict, inventory_dict, spell_dict, visited_before):
    visited_before = have_you_visited_this_room_before(visited_before)
    exit_key = False
    
    slow_print("\nThis room appears to be a small office/break room of sorts. The only furniture still present is a heavy half rotten desk.")
    
    action_choice = actions_while_exploring(inventory_dict)
    trinket_used = None

    while action_choice != "NAVIGATE":

        if action_choice == "1" or action_choice == "SEARCH":
            slow_print("\nUnderneath the desk you find a small silver lockbox. It is bolted to the floor. It has a SILVER KEYHOLE.")
            time.sleep(2)

        elif action_choice == "3" or action_choice == "CAST":
            stat_dict = casting_spells_outside_combat(stat_dict, spell_dict)

        elif action_choice == "4" or action_choice == "USE":
            mixed_dict = using_trinket_outside_combat(stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            trinket_used = mixed_dict[2]

        elif action_choice == "5" or action_choice == "VIEW":
            clear_screen()
            veiw_character_sheet(stat_dict, inventory_dict, spell_dict)
        
        elif action_choice == "6" or action_choice == "EQUIPT WEAPON":
            stat_dict = equipt_weapon(inventory_dict, stat_dict)
        
        elif action_choice == "7" or action_choice == "EQUIPT ARMOR":
            stat_dict = equipt_armor(inventory_dict, stat_dict)

        if trinket_used == "SILVER KEY":
            slow_print("\nYou insert the SILVER KEY into the SILVER KEYHOLE, it turns and 'click!' The lockbox opens!")
            time.sleep(1)
            slow_print("\nInside you find 15 GOLD PIECES and a heavy IRON KEY")
            inventory_dict["Trinkets"].pop("SILVER KEY")
            stat_dict["GP"] += 15
            inventory_dict = add_trinket_to_inventory( inventory_dict, ["IRON KEY", 0, 1])
            trinket_used = None
            time.sleep(2)

        clear_screen()
        action_choice = actions_while_exploring(inventory_dict)


    location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
    if location == "Y" or location == "YES":
        location = "ENTRANCE ROOM"
    else:
        location = "GUARD ROOM"
    
    if "Iron KEY" in inventory_dict["Trinkets"]:
        exit_key = True

    return stat_dict, inventory_dict, location, visited_before, exit_key



def have_you_visited_this_room_before(visited_before):
    visited_before = True
    return visited_before



def tutorial_combat(stat_dict, inventory_dict, spell_dict):
    '''teaches the player the combat system'''
    monster_stat_dict = {
        "Name" : "Gaint Rat",
        "HP" : 5,
        "DP": 0,
        "AP": 2,
        "GP" : 0,
        "SL" : 6,
    }

    pre_combat_stat_dict = stat_dict.copy()
    pre_combat_Monster_stat_dict = monster_stat_dict.copy()

    monster_effecting_player = False

    mixed_dict = players_first_turn(stat_dict, monster_stat_dict)
    stat_dict = mixed_dict[0]
    monster_stat_dict = mixed_dict[1]
    
    monsters_first_turn(monster_stat_dict)

    mixed_dict = players_second_turn(stat_dict, spell_dict, monster_stat_dict)
    stat_dict = mixed_dict[0]
    monster_stat_dict = mixed_dict[1]

    stat_dict = monsters_second_trun(stat_dict, monster_stat_dict)
    
    mixed_dict = players_third_turn(stat_dict, inventory_dict)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]

    time.sleep(3)
    slow_print("\nAlright you know the basics, the rest is up to you, good luck.",0.02)
    time.sleep(1)

    while stat_dict["CHP"] > 0 and monster_stat_dict["HP"] > 0:
        mixed_dict = monsters_turn(stat_dict, monster_stat_dict, pre_combat_stat_dict ,pre_combat_Monster_stat_dict, monster_effecting_player)
        stat_dict = mixed_dict[0]
        monster_stat_dict = mixed_dict[1]
        monster_effecting_player = mixed_dict[2]

        if stat_dict["CHP"] > 0:
            mixed_dict = players_turn(stat_dict, spell_dict, monster_stat_dict, pre_combat_stat_dict, inventory_dict)
            stat_dict = mixed_dict[0]
            monster_stat_dict = mixed_dict[1]
            inventory_dict = mixed_dict [2]

        clear_screen()
    
    print("-" * 90)
    print("                                  **Giant Rat Slain**") # check this later to ensure its centered
    print("-" * 90)
    time.sleep(0.5)
    return stat_dict, inventory_dict



def players_first_turn(stat_dict, monster_stat_dict):

    print("-" * 90)
    slow_print("Welcome to combat, its pretty simple, lets show you the basics.",0.02)
    time.sleep(1)
    slow_print("It's your turn, so first a short summary of your vitals will show up.",0.02)
    time.sleep(1)
    print('\n' + stat_dict["Name"])
    print(f"""Hit Points: {stat_dict["CHP"]}/{stat_dict["MHP"]}| Stamina: {stat_dict["CSP"]}/{stat_dict["MSP"]}| Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}""")
    time.sleep(2)
    slow_print("""\nLets start off with a baisc attack, either type in "ATTACK" (only spelling matters) or press 1.""",0.02)
    time.sleep(0.5)

    combat_choice = question_with_multiple_answers("What do you do on your turn? \n1: ATTACK with your weapon?", "Invaild input, please try again ", [
        "ATTACK", "1"])
    
    if combat_choice != "ATTACK" and combat_choice != "1":
        slow_print("""Failing to input a vaild arugment 3 times in a row, forces the system to choose for you. In this instance "ATTACK" has been choosen
for you.""", 0.02)
        time.sleep(2)

    stat_dict["CSP"] -= 1
    monster_stat_dict["HP"] -= stat_dict["AP"]
    slow_print(f"You hit the {monster_stat_dict["Name"]} for {stat_dict["AP"]} point/s of damage.", 0.02)
    time.sleep(1.5)
    
    clear_screen()
    return stat_dict, monster_stat_dict



def monsters_first_turn(monster_stat_dict):
    slow_print("""\nOn the Monster's turn the system will give a brief summary of the Monster's vitals, then the monster will randomly pick an action
to preform.\n""",0.02)
    time.sleep(1)
    print(monster_stat_dict["Name"])
    print(f"Health: {monster_stat_dict["HP"]}")
    time.sleep(1)
    slow_print(f"The {monster_stat_dict["Name"]} took the doge action!", 0.02)
    time.sleep(0.75)
    pass



def players_second_turn(stat_dict, spell_dict, monster_stat_dict):
    print('\n' + stat_dict["Name"])
    print(f"""Hit Points: {stat_dict["CHP"]}/{stat_dict["MHP"]}| Stamina: {stat_dict["CSP"]}/{stat_dict["MSP"]}| Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}""")
    time.sleep(1.5)
    slow_print(f"""\nNotice that your stamina decreased by 1. This happens every time you attack normally. Now because the {monster_stat_dict["Name"]} 
decied to take the doge action it will be harder to hit normally for our next turn, thus giving a higher possibliy that our stamina might be wasted.""", 0.02)
    time.sleep(2)
    slow_print("""\nThankfully we know a spell that can help us out. Type "CAST" or 2 then press enter.""",0.02)
    time.sleep(0.5)

    combat_choice = question_with_multiple_answers("\nWhat do you do on your turn? \n1: ATTACK with your weapon? \n2: CAST a spell?","Invaild input, please try again ", ["CAST", "2"], "2")

    if combat_choice != "CAST" and combat_choice != "2":
        slow_print("""Failing to input a vaild arugment 3 times in a row, forces the system to choose for you. In this instance "CAST" has been choosen
for you.""", 0.02)
        time.sleep(2)

    mixed_dict = tutorial_spell_attack(stat_dict, spell_dict, monster_stat_dict)

    clear_screen()
    return mixed_dict



def tutorial_spell_attack(stat_dict,spell_dict, monster_stat_dict):
    counter = 0
    print("\nSpells:")

    for key in spell_dict:
        counter += 1
        print(counter,": ", key, " | Power:", spell_dict[key][1], " | Cost:", spell_dict[key][0])
    
    time.sleep(1)    
    slow_print("""\nYour BASIC MAGIC MISSILE spell always hits the enemy, no matter what. Type "BASIC MAGIC MISSILE" or Type 1\n""", 0.02)
    time.sleep(1)

    spell_choice = question_with_multiple_answers("Which spell would you liked to cast? ", "Invaild input, please try again ", ["BASIC MAGIC MISSILE", "1"])


    if spell_choice != "BASIC MAGIC MISSILE" and spell_choice != "1":
        slow_print("""Failing to input a vaild arugment 3 times in a row, forces the system to choose for you. In this instance "BASIC MAGIC MISSILE"
has been choosen for you.""")
        time.sleep(1.25)

    if stat_dict["CMP"] >= 2:
        stat_dict["CMP"] -= 2
        monster_stat_dict = basic_magic_missile(monster_stat_dict)
    else:
        slow_print("The spell failed because... How are you already out of mana? Seriously!")
        time.sleep(1)

    return stat_dict, monster_stat_dict



def monsters_second_trun(stat_dict, monster_stat_dict):
    time.sleep(1)
    print('\n' + monster_stat_dict["Name"])
    print(f"Health: {monster_stat_dict["HP"]}")
    time.sleep(2)
    print("!!Critical Hit!!")
    attack_power = monster_stat_dict["AP"] * 2
    stat_dict["CHP"] -= attack_power
    slow_print(f"The {monster_stat_dict["Name"]} hit you for {attack_power} point/s of damage.", 0.02)
    time.sleep(1)
    return stat_dict



def players_third_turn(stat_dict, inventory_dict):
    print('\n' + stat_dict["Name"])
    print(f"""Hit Points: {stat_dict["CHP"]}/{stat_dict["MHP"]}| Stamina: {stat_dict["CSP"]}/{stat_dict["MSP"]}| Mana: {stat_dict["CMP"]}/{stat_dict["MMP"]}""")
    time.sleep(3)
    slow_print("""\nLooks like you've been hit pretty bad! I'll give you this potion for free.""", 0.02)
    time.sleep(2)
    inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY HEALING POTION", 0, 1])
    time.sleep(3)
    slow_print("""\nYou better use that potion right away. Type "USE" or 3 then press enter.""", 0.02)
    time.sleep(2)

    combat_choice = question_with_multiple_answers("\nWhat do you do on your turn? \n1: ATTACK with your weapon? \n2: CAST a spell? \n3: USE a Trinket?", "Invaild input, please try again ", [
    "USE", "3"], "3")

    if combat_choice != "USE" and combat_choice != "3":
        slow_print("""Failing to input a vaild arugment 3 times in a row, forces the system to choose for you. In this instance "USE" has been choosen
for you.""", 0.02)
        time.sleep(1)

    mixed_dict = tutorial_use_trinkets(stat_dict, inventory_dict)

    clear_screen()
    return mixed_dict



def tutorial_use_trinkets(stat_dict, inventory_dict):
    counter = 0
    print("\nTrinkets:")

    for key in inventory_dict["Trinkets"]:
        counter +=1
        print(counter,": ", key, " | Value:", inventory_dict["Trinkets"][key][0], " | Quanity:", inventory_dict["Trinkets"][key][1])

    trinket_choice = question_with_multiple_answers("""Type "TINY HEALING POTION" or 1 and then enter to use the potion. (It should heal you by 2-4) points if possible. """,
    "Invaild input, please try again ", ["TINY HEALING POTION", "1"])

    if  trinket_choice != "TINY HEALING POTION" and  trinket_choice != "1":
        slow_print("""Failing to input a vaild arugment 3 times in a row, forces the system to choose for you. In this instance "TINY HEALING POTION"
has been choosen for you.""")
        time.sleep(2)
    
    mixed_dict = using_tiny_healing_potion(stat_dict, inventory_dict)

    return mixed_dict



def empty_room_loot_table(stat_dict, inventory_dict, has_searched_before):
    '''when player searches for treasure gives a random chance to determine what they find'''
    slow_print("\nYou search the room.")
    time.sleep(1.5)

    if has_searched_before == False:
        search = random.randint(1,100)
        if search < 75:
            slow_print("You find nothing of value.")
        elif search >= 75 and search <= 99:
            slow_print("You find a single GOLD PIECE")
            stat_dict["GP"] += 1
        elif search == 100:
            print("You find a well hidden satchel containing ", end="")
            loot = random.randint(1,10)
            
            if loot <=7:
                slow_print("10 GOLD PIECES")
                stat_dict["GP"] += 10
            elif loot == 8:
                slow_print("10 GOLD PIECES and a TINY POTION OF HEALING")
                stat_dict["GP"] += 10
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY POTION OF HEALING", 5, 1])
            elif loot == 9:
                slow_print("10 GOLD PIECES and a TINY POTION OF STAMINA")
                stat_dict["GP"] += 10
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY POTION OF STAMINA", 5, 1])
            elif loot == 10:
                slow_print("10 GOLD PIECES and a TINY POTION OF MANA")
                stat_dict["GP"] += 10
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY POTION OF MANA", 5, 1])

    else:
        slow_print("You search the barren room once more, and find nothing.")
    
    time.sleep(1.5)
    has_searched_before = True
    return stat_dict, inventory_dict, has_searched_before



def half_decent_supplies_loot_table(stat_dict, inventory_dict, has_searched_before):
    '''when player searches for treasure gives a random chance to determin what they find'''
    print('\nYou search the room.')
    time.sleep(1.5)

    if has_searched_before == False:
        search = random.randint(1,100)
        if search < 10:
            slow_print("You find nothing of value.")

        elif search < 50:
            gold = random.randint(5,12)
            slow_print(f"You find {gold} GOLD PIECES.")
            stat_dict["GP"] += gold

        elif search < 99:
            potion_list = ["TINY HEALING POTION", "TINY STAMINA POTION", "TINY MANA POTION"]
            gold = random.randint(10, 25)
            potion = random.choice(potion_list)
            slow_print(f"You find {gold} GOLD PIECES and 1 {potion}")
            stat_dict["GP"] += gold
            inventory_dict = add_trinket_to_inventory(inventory_dict, [potion, 5, 1])

        elif search == 100:
            slow_print("You find 30 GOLD PIECES and 1 of each of the following TINY potions, HEALING, STAMINA, and MANA")
            stat_dict["GP"] += 30
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY HEALING POTION", 5, 1])
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY STAMINA POTION", 5, 1])
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY MANA POTION", 5, 1])
    else:
        search = random.randint(1, 100)
        if search < 95:
            slow_print("You find nothing of value.")
        else:
            slow_print("You find a single left over GOLD PIECE.")
            stat_dict["GP"] += 1

    time.sleep(2)
    has_searched_before = True
    return stat_dict, inventory_dict, has_searched_before






def dungeon1_the_sewers(stat_dict, inventory_dict, spell_dict):
    '''The 1st real dungeon's parent function.'''
    slow_print('''\nYou climb down the rope tied to the center of the grate. The night sky disappears above you. You reach the bottom of the rope before you
reach the floor. Trusting your gut you let go and fall into the darkness.''')
    time.sleep(1.5)
    print()
    print("-" * 75)
    print("                         --The Sewers of Tyrus-- ")
    print("-" * 75)
    time.sleep(2)
    slow_print('''\nYour fall only lasts for about 10ft before your feet hit hard stone. Lighting a torch you can make out the layout of this entrance.
Four archways divide this room from each of the adjoined sections. One each to the North, East, South, and West. You remember to keep in
mind the castle is north of you. The gray mud drips from the edges down and then flows outward towards every exit of this room.''')
    time.sleep(3)

    exit_key = False
    location = "ENTRANCE ROOM"

    visited_sewer_entrance_room = False
    visited_sewer_the_pit = False
    visited_sewer_collapsed_tunnel = False
    visited_sewer_old_camp = False
    visited_sewer_clogged_pipe = False
    visited_sewer_long_tunnel = False
    visited_sewer_lever_room = False
    visited_sewer_door_room = False

    entrance_romm_searched = False
    the_pit_searched = False
    collapsed_tunnel_searched = False
    old_camp_searched = False
    clogged_pipe_searched = False
    long_tunnel_searched = False
    lever_room_searched = False
    door_room_searched = False

    gate_opend = False
    south_of_mud_pool = True
    first_time_through_the_mud = True
    exit_lever_pulled = False

    while exit_key == False:

        if location == "ENTRANCE ROOM":
            mixed_dict = sewer_entrance_room(stat_dict, inventory_dict, spell_dict, visited_sewer_entrance_room, entrance_romm_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_entrance_room = mixed_dict[2]
            location = mixed_dict[3]
            entrance_romm_searched = mixed_dict[4]

        elif location == "THE PIT":
            mixed_dict = sewer_the_pit(stat_dict, inventory_dict, spell_dict, visited_sewer_the_pit, the_pit_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_the_pit = mixed_dict[2]
            location = mixed_dict[3]
            the_pit_searched = mixed_dict[4]

        elif location == "COLLAPSED TUNNEL":
            mixed_dict = sewer_collasped_tunnel(stat_dict, inventory_dict, spell_dict, visited_sewer_collapsed_tunnel, collapsed_tunnel_searched, gate_opend)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_collapsed_tunnel = mixed_dict[2]
            location = mixed_dict[3]
            collapsed_tunnel_searched = mixed_dict[4]
            gate_opend = mixed_dict[5]
        
        elif location == "OLD CAMP":
            mixed_dict = sewer_old_camp(stat_dict, inventory_dict, spell_dict, visited_sewer_old_camp, old_camp_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_old_camp = mixed_dict[2]
            location = mixed_dict[3]
            old_camp_searched = mixed_dict[4]
        
        elif location == "CLOGGED PIPE":
            mixed_dict = sewer_clogged_pipe(stat_dict, inventory_dict, spell_dict, visited_sewer_clogged_pipe, clogged_pipe_searched)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_clogged_pipe = mixed_dict[2]
            location = mixed_dict[3]
            clogged_pipe_searched = mixed_dict[4]

        elif location == "LONG TUNNEL":
            mixed_dict = sewer_long_tunnel(stat_dict, inventory_dict, spell_dict, visited_sewer_long_tunnel, long_tunnel_searched, south_of_mud_pool, first_time_through_the_mud)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_long_tunnel = mixed_dict[2]
            location = mixed_dict[3]
            long_tunnel_searched = mixed_dict[4]
            south_of_mud_pool = mixed_dict[5]
            first_time_through_the_mud = mixed_dict[6]

        elif location == "LEVER ROOM":
            mixed_dict = sewer_lever_room(stat_dict, inventory_dict, spell_dict, visited_sewer_lever_room, lever_room_searched, exit_lever_pulled)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_lever_room = mixed_dict[2]
            location = mixed_dict[3]
            lever_room_searched = mixed_dict[4]
            exit_lever_pulled = mixed_dict[5]

        elif location == "DOOR ROOM":
            mixed_dict = sewer_door_room(stat_dict, inventory_dict, spell_dict, visited_sewer_door_room, door_room_searched, exit_lever_pulled)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            visited_sewer_door_room = mixed_dict[2]
            location = mixed_dict[3]
            door_room_searched = mixed_dict[4]

        elif location == "DEATH" or location == "Exit":
            exit_key = True
        
        clear_screen()


    print("-" * 75)
    print("                         --Dungeon Cleared-- ")
    print("-" * 75)
    print()
    time.sleep(2)
    checkpoint = 4
    return stat_dict, inventory_dict, spell_dict, checkpoint



def sewer_entrance_room(stat_dict, inventory_dict, spell_dict,  visited_sewer_entrance_room, has_searched_before):

    if visited_sewer_entrance_room:
        slow_print('''\nFour archways divide this room from each of the adjoined sections. One each to the North, East, South, and West. You remember to keep
in mind the castle is north of you. ''')
        time.sleep(1.25)

    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, has_searched_before)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]
    has_searched_before = mixed_dict[2]

    location = question_with_multiple_answers("\nWhere do you go? \n1: North \n2: East \n3: South \n4: West", "Where do you go? ",[
        "1", "2", "3", "4", "N", "E", "S", "W", "NORTH", "EAST", "SOUTH", "WEST"])

    location = multiple_answer_decider(location, [["1", "N", "NORTH"],["2", "E", "EAST"], ["3", "S", "SOUTH"], ["4", "W", "WEST"]],
    ["THE PIT", "COLLAPSED TUNNEL", "OLD CAMP", "CLOGGED PIPE"])

    visited_sewer_entrance_room = have_you_visited_this_room_before(visited_sewer_entrance_room)
    return stat_dict, inventory_dict, visited_sewer_entrance_room, location, has_searched_before



def sewer_the_pit(stat_dict, inventory_dict, spell_dict, visited_sewer_the_pit, has_searched_before):
    jump_in = "N"
      
    if visited_sewer_the_pit == False:
        slow_print('''\nAs you walk past the arch on the north side, you travel on one of the side paths, letting the mud flow trough a central channel dug
into the floor. You soon reach a drop off, the mud flows off the side on a seemingly endless pit. You peer down into the darkness but see
nothing in return.''')
        time.sleep(2.25)
        slow_print('''\nThe words "Join us" echo through your mind, first as a child's voice then a women's, and then an echoing barraige of voices all shouting
"Join us" bounce through your mind, all calling from deep within the pit.\n''')
        time.sleep(1.5)
        jump_in = yes_or_no_question("Do you head the voices within and join them? (Y/N) ", True)

        if jump_in == "Y" or jump_in == "YES":
            slow_print("""\nYou leap into the void, and fall for what seems like miles before hitting the muddy bottom. The surface tension of the mud from such a
long fall kills you instantly...""")
            time.sleep(1.25)
            stat_dict["CHP"] = 0
        else:
            slow_print("""\nYou resist the calling voices and step away from the pit. Probably for the best to avoid this room.""")
            time.sleep(1)
    
    else:
        slow_print('''\nThe mud flows off the side on a seemingly endless pit. Probably for the best to avoid this room.''')
        time.sleep(2)
    
    if stat_dict["CHP"] > 0:

        mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, has_searched_before)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        has_searched_before = mixed_dict[2]
    
        visited_sewer_the_pit = have_you_visited_this_room_before(visited_sewer_the_pit)
        location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
        if location == "Y" or location == "YES":
            location = "ENTRANCE ROOM"
        else:
            location = "THE PIT"
    else:
        location = "DEATH"

    return stat_dict, inventory_dict, visited_sewer_the_pit, location, has_searched_before



def sewer_collasped_tunnel(stat_dict, inventory_dict, spell_dict, visited_sewer_collapsed_tunnel, has_searched_before, gate_opened):
    '''locked iron grate halfway through room, need the RUSTED KEY to advance. RUSTED KEY found in CLOGGED PIPE room.'''
    trinket_used = None
    choice = "Y"

    if visited_sewer_collapsed_tunnel == False:
        slow_print("""\nWalking past the archway, you enter perpendicular to the route of this large tunnel which heads south. The tunnel is divided halfway
through by a large iron gate, which looks to have a RUSTED PADLOCK and chain keeping it closed. A Giant Rat licks up the flowing mud begrudgingly. It
doesn't see you, do you continue into the room or head back to the ENTRANCE ROOM before it notices? \n""")
        time.sleep(2.75)
        choice = yes_or_no_question("Do you stay to fight the Giant Rat? (Y/N) ")

        if choice == "Y" or choice == "YES":
            mixed_dict = combat(stat_dict, inventory_dict, spell_dict, giant_rat_stats)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

            if stat_dict["CHP"] > 0:
                visited_sewer_collapsed_tunnel = have_you_visited_this_room_before(visited_sewer_collapsed_tunnel)
        else: 
            slow_print("""\nYou slowly back away from the rat back into the ENTRANCE ROOM.""")
            time.sleep(1)
            location = "ENTRANCE ROOM"
    else:
        if gate_opened == False:
            slow_print("""\nYou enter perpendicular to the route of this large tunnel which heads south. The tunnel is divided halfway through by a large iron gate,
which looks to have a RUSTED PADLOCK and chain keeping it closed.""")
            time.sleep(1.5)
        else:
            slow_print('''\nYou enter perpendicular to the route of this large tunnel which heads in the north/south direction. The tunnel is divided halfway through
by a large iron gate, which stands open allowing you to pass freely.''')
            time.sleep(1.5)
    
    if choice == "YES":
        choice = "Y"

    if stat_dict["CHP"] > 0 and choice == "Y":
        action_choice = actions_while_exploring(inventory_dict)

        while action_choice != "NAVIGATE":
            trinket_used = None

            if action_choice == "1" or action_choice == "SEARCH":
                mixed_dict = empty_room_loot_table(stat_dict, inventory_dict, has_searched_before)
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

            if trinket_used == "RUSTED KEY":
                slow_print("""\nYou slide the RUSTED KEY into the RUSTED PADLOCK, at first if doesn't budge. But after applying some force 'Clank'! The internal
mechanisms of the padlock all shatter and crumble. The padlock opens, the chain falls to the floor, and the gate slowly swings wide open allowing you
to pass through. You see further down the tunnel collapses in on itself, but theres a passageway thats been dug out which leads further East.""")
                inventory_dict["Trinkets"].pop("RUSTED KEY")
                gate_opened = True
                trinket_used = None
                time.sleep(3)

            clear_screen()
            action_choice = actions_while_exploring(inventory_dict)

        if gate_opened:
            location = question_with_multiple_answers("\nWhere do you go? \n1: West back to the ENTRANCE ROOM \n2: East", "Where do you go? ",[
                "1", "2", "E", "W", "EAST", "WEST", "ENTRANCE ROOM"])

            location = multiple_answer_decider(location, [["1", "W", "WEST", "ENTRANCE ROOM"], ["2", "E", "EAST"]], ["ENTRANCE ROOM", "LONG TUNNEL"])
        else:
            # Gate is not opened, so only option is to go back to entrance room
            location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
            if location == "Y" or location == "YES":
                location = "ENTRANCE ROOM"
            else:
                location = "COLLAPSED TUNNEL"

    elif stat_dict["CHP"] <= 0:
        location = "DEATH"

    return stat_dict, inventory_dict,visited_sewer_collapsed_tunnel ,location, has_searched_before, gate_opened



def sewer_old_camp(stat_dict, inventory_dict, spell_dict, visited_sewer_old_camp, old_camp_searched):

    if visited_sewer_old_camp == False:
        slow_print("""\nPassing the archway, it's clear that this southward tunnel at some recent time was used as a makeshift campsite. Dividing this tunnel
is a broken iron grate behind which lays a shiny CHIPPED DAGGER.""")
        time.sleep(1.5)
    else:
        slow_print('''\nPassing the archway, it's clear that this southward tunnel at some recent time was used as a makeshift campsite. Dividing this tunnel
is a broken iron grate.''')
        time.sleep(1.25)
    
    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, half_decent_supplies_loot_table, old_camp_searched)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]
    old_camp_searched = mixed_dict[2]

    location = question_with_multiple_answers("\nWhere do you go? \n1: North back to the ENTRANCE ROOM \n2: South through the grate?", "Where do you go? ", [
        "1", "2", "N", "S", "NORTH", "SOUTH", "ENTRANCE ROOM"])
    
    location = multiple_answer_decider(location, [["1", "N", "NORTH", "ENTRANCE ROOM"], ["2", "S", "SOUTH"]],["ENTRANCE ROOM", "PAST THE GRATE"])
        
    if location == "PAST THE GRATE":

        if visited_sewer_old_camp == False:
            slow_print(f'''\nAs you shimmy through the opening in the grate smearing mug all over yourself, you hear a loud screech! Looking above you see the form of
what looks to be a Giant Bat. It has GOLDEN RUNES on it's forhead and chest. You barely manage to get to your feet in time, and swing your {stat_dict["EW"]}
in hopes to keep it away.''')
            time.sleep(3)

            clear_screen()
            mixed_dict = combat(stat_dict, inventory_dict, spell_dict, giant_bat_stats)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

            if stat_dict["CHP"] > 0:
                print()
                print('''With the Giant Bat killed, you can finally claim your prize.''')

                inventory_dict = add_weapon_to_inventory(inventory_dict, ["CHIPPED DAGGER", 5, 2])
            else:
                location = "DEATH"

        if stat_dict["CHP"] > 0:
            slow_print('''\nThere's not much else on this side of the grate, the rest of the tunnel has been clogged by the mud.''')
            time.sleep(1)
            visited_sewer_old_camp = have_you_visited_this_room_before(visited_sewer_old_camp)
            
            location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
            if location == "Y" or location == "YES":
                location = "ENTRANCE ROOM"
            else:
                location = "OLD CAMP"
    
    return stat_dict, inventory_dict, visited_sewer_old_camp, location, old_camp_searched



def sewer_clogged_pipe(stat_dict, inventory_dict, spell_dict, visited_sewer_clogged_pipe, clogged_pipe_searched):

    if visited_sewer_clogged_pipe == False:
        rod = "N"
        slow_print('''\nPassing the archway You enter this room perpendicular to its path as it turns and heads north. Mud flows slowly but pools up on the far
side. The far side of this path seems to be clogged by mud and trash. Within this mound of mud and trash, a RUSTED ROD pokes out.''')
        time.sleep(2)

        rod = yes_or_no_question("Do you grab the RUSTED ROD? (Y/N) ", True)

        if rod == "Y" or rod == "YES":
            slow_print("""\nYou pull on the RUSTED ROD and it slides out along with a quite a large amount of mud which flows around your legs. Along closer inspection 
of the ROD, it apears to be a RUSTED KEY.""")
            time.sleep(1.25)
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["RUSTED KEY", 0, 1])
            time.sleep(1)
            slow_print('''\nAs you turn around to head back to the ENTRANCE ROOM, you notice that a portion of the mud moves past your legs again
irregularly, almost like its alive.''')
            time.sleep(1.25)
            slow_print('''\nYou see infront of you as a mound of gray mud rises from the rest and swings a lump of mud at you.''')
            time.sleep(2)

            mixed_dict = combat(stat_dict, inventory_dict, spell_dict, slime_stats)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

            if stat_dict["CHP"] > 0:
                visited_sewer_clogged_pipe = have_you_visited_this_room_before(visited_sewer_clogged_pipe)
        else:
            slow_print('''\nYou decide against pulling RUSTED ROD from the pile of trash.''')
            time.sleep(1)

    else:
        slow_print('''\nPassing the archway You enter this room perpendicular to its path as it turns and heads north. Mud flows slowly but pools up on the far
side. The far side of this path seems to be clogged by mud and trash.''')
        time.sleep(1.5)

    if stat_dict["CHP"] > 0:

        mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, half_decent_supplies_loot_table, clogged_pipe_searched)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        clogged_pipe_searched = mixed_dict[2]
    
        location = yes_or_no_question("Do you head back to the ENTRANCE ROOM? (Y/N) ", True)
    
        if location == "Y" or location == "YES":
            location = "ENTRANCE ROOM"
        else:
            location = "CLOGGED PIPE"

    else:
        location = "DEATH"
    return stat_dict, inventory_dict, visited_sewer_clogged_pipe, location, clogged_pipe_searched



def sewer_long_tunnel(stat_dict, inventory_dict, spell_dict, visited_sewer_long_tunnel, long_tunnel_searched, south_of_mud_pool, first_time_through_the_mud):
    trinket_used = None
    exit_room = False

    if visited_sewer_long_tunnel == False:
        stat_dict = leveling_up(stat_dict)

        slow_print('''\nAs you pass through the dug out passage way to the east, you see that it breaks into another collpased tunnel, but heads back northward.
The gray mud flows through this dug out passgae and into the new tunnel, and pools in the middle of this quite long streach of sewer. At
the far end of the tunnel you see two exits, one Northward and one that heads back West.''')
        time.sleep(2.5)
        visited_sewer_long_tunnel = have_you_visited_this_room_before(visited_sewer_long_tunnel)
    else:
        slow_print('''\nYou walk back into the long tunnel which heads North/South, the room is partitoned by a pool of gray mud in the middle. There are three
exits in total two to the West and one to the North.''')
        time.sleep(1.5)
        
    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, long_tunnel_searched)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]
    long_tunnel_searched = mixed_dict[2]

    while exit_room == False:
        

        if south_of_mud_pool:

            location = question_with_multiple_answers("\nWhere do you go? \n1: West back towards the Entrance \n2: North through the Mud Pool", "Where do you go? ", [
                "1", "2", "3", "N", "W", "NORTH", "WEST"])

            location = multiple_answer_decider(location, [["2", "N", "NORTH"],["1", "W", "WEST"]], ["THROUGH THE MUD", "COLLAPSED TUNNEL"])

            if location == "COLLAPSED TUNNEL":
                exit_room = True
        
            if location == "THROUGH THE MUD":
                south_of_mud_pool = False
                slow_print("""\nYou trudge through the deep mud. It burns dealing 1 point of damage to you.""")
                stat_dict["CHP"] -= 1
                time.sleep(1)

                if first_time_through_the_mud:
                    first_time_through_the_mud = False

                    slow_print('''\nAs you reach the other side of the Mud Pool, part of the Mud starts moving on its own, it rises up in front of you and attacks!''')
                    time.sleep(1)

                    mixed_dict = combat(stat_dict, inventory_dict, spell_dict, slime_stats)
        
                if stat_dict["CHP"] > 0:
                    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, long_tunnel_searched)
                    stat_dict = mixed_dict[0]
                    inventory_dict = mixed_dict[1]
                    long_tunnel_searched = mixed_dict[2]

                else:
                    location = "DEATH"
                    exit_room = True
        else:

            location = question_with_multiple_answers("\nWhere do you go? \n1: South through the Mud Pool \n2: West deeper into the sewers \n3: North deeper into the sewers", "Where do you go? ",[
                "1", "2", "3", "N", "W", "S", "NORTH", "WEST", "SOUTH"])

            location = multiple_answer_decider(location, [["1", "S", "SOUTH"], ["2", "W", "WEST"], ["3", "N", "NORTH"]],["THROUGH THE MUD", "DOOR ROOM", "LEVER ROOM"])
        
            if location == "THROUGH THE MUD":
                south_of_mud_pool = True
                slow_print("""\nYou trudge through the deep mud. It burns dealing 1 point of damage to you.""")
                stat_dict["CHP"] -= 1
                time.sleep(1)
        
                if stat_dict["CHP"] > 0:
                    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, long_tunnel_searched)
                    stat_dict = mixed_dict[0]
                    inventory_dict = mixed_dict[1]
                    long_tunnel_searched = mixed_dict[2]

                else:
                    location = "DEATH"
                    exit_room = True
            else:
                exit_room = True
    
    return stat_dict, inventory_dict, visited_sewer_long_tunnel, location, long_tunnel_searched, south_of_mud_pool, first_time_through_the_mud



def sewer_lever_room(stat_dict, inventory_dict, spell_dict, visited_sewer_lever_room, lever_room_searched, exit_lever_pulled):
    fight = "N"
    location = "LEVER ROOM"
    action_choice = ""

    if visited_sewer_lever_room == False:
        slow_print('''\nYou pass an archway and see that the mud doesn't flow into this room. The channel instead had turned and gone to the west. In front of
you is a strange site for the sewers. This room is of a much higher quality build, the dampness and humidity of the sewers does not flow
into this room, which has been built to look like a small arena. On the far side of the room is a LEVER connected to the wall, standing
in between you and the aforementioned lever is an animated SKELETON, decked out in dented black armor with gold trimmings.''')
        time.sleep(4)
        slow_print('''\nYou see the SKELETON'S eye sockets are lit up by bright red runes carved into the insides of said eye sockets. It stares at you waiting
for your approach.''')
        time.sleep(1.25)

        fight = yes_or_no_question("Do you approach the Skeleton? (Y/N) ")

        if fight == "Y" or fight == "YES":
            slow_print('''\nYou approach the guardian and ready yourself for a fight.''')
            time.sleep(1)

            mixed_dict = combat(stat_dict, inventory_dict, spell_dict, guardian_of_Zargonud)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]

            if stat_dict["CHP"] > 0:
                visited_sewer_lever_room = have_you_visited_this_room_before(visited_sewer_lever_room)
            else:
                location = "DEATH"
        else:
            slow_print('''\nYou decide to slowly back away from the SKELETON''')
            time.sleep(1)
            location = "LONG TUNNEL"
    else:
        slow_print('''\nThis room is of a much higher quality build, the dampness and humidity of the sewers does not flow into this room, which has been built
to look like a small arena. On the far side of the room is a LEVER connected to the wall''')
        time.sleep(1.5)


    if location != "LONG TUNNEL" and location != "DEATH":
        special_1 = False
        print('''\n(Select SPECIAL 1 to pull the level.)''')
        while action_choice != "NAVIGATE":
            mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, lever_room_searched, None, ["SPECIAL 1"])
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]
            lever_room_searched = mixed_dict[2]
            special_1 = mixed_dict[5]
            action_choice = mixed_dict[6]

            if special_1:
                print('''\nYou pull the lever and you hear a 'Click' and then the sound of stone grinding against stone echos from the sewer.''')
                time.sleep(3)
                exit_lever_pulled = True
            
        location = yes_or_no_question("Do you head back to the Sewers? (Y/N) ", True)
    
        if location == "Y" or location == "YES":
            location = "LONG TUNNEL"
        else:
            location = "LEVER ROOM"
            
    return stat_dict, inventory_dict, visited_sewer_lever_room, location, lever_room_searched, exit_lever_pulled




def sewer_door_room(stat_dict, inventory_dict, spell_dict, visited_sewer_door_room, door_room_searched, exit_lever_pulled):

    if visited_sewer_door_room == False:

        if exit_lever_pulled == False:
            slow_print('''\nThis room heads further north. In the center of the room is a large grate in the floor which the gray mud flows through downward.
Beyond the floor grate the room's construction changes to be built of a darker stone brick, which seems to be of a more ancient style. At the far
end of the room is a stone door with a symbol of a skull surrounded in a dim glowing red rune circle. ''')
            time.sleep(2.75)
        else:
            slow_print('''\nThis room heads further north. In the center of the room is a large grate in the floor which the gray mud flows through downward.
Beyond the floor grate the room's construction changes to be built of a darker stone brick, which seems to be of a more ancient style. At the far
end of the room is an archway which looks to lead into a crypt of sorts, you seen coffins line the walls of the passageway beyound the archway.''')
            time.sleep(3)
    else:
        if exit_lever_pulled == False:
            slow_print('''\nThis room heads further north. Beyond the floor grate is a stone door with a symbol of a skull surrounded in a dim glowing red rune
circle.''')
            time.sleep(1)
        else:
            slow_print('''\nThis room heads further north. Beyond the floor grate is an archway which looks to lead into a crypt of sorts, you seen coffins line
the walls of the passageway beyound the archway.''')
            time.sleep(1.25)
    
    mixed_dict = using_actions_while_exporling(stat_dict, inventory_dict, spell_dict, empty_room_loot_table, door_room_searched)
    stat_dict = mixed_dict[0]
    inventory_dict = mixed_dict[1]
    door_room_searched = mixed_dict[2]


    if exit_lever_pulled == False:

        location = yes_or_no_question("Do you head back to the Sewers? (Y/N) ", True)
    
        if location == "Y" or location == "YES":
            location = "LONG TUNNEL"
        else:
            location = "DOOR ROOM"
    else:

        location = question_with_multiple_answers("\nWhere do you go? \n1: East back into the SEWERS \n2: North into the CRYPT", "Where do you go? ", [
            "1", "2", "N", "E", "NORTH", "EAST", "CRYPT", "SEWERS"], "2")

        location = multiple_answer_decider(location, [["2", "N", "NORTH", "CRYPT"], ["1", "W", "WEST", "SEWERS"]],["Exit", "LONG TUNNLE"])

    return stat_dict, inventory_dict, visited_sewer_door_room, location, door_room_searched