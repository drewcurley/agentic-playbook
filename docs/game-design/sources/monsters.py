###This file contains al functions pretaining directly to monsters###
import random
import time



def goblin_stats():
    monster_stat_dict = {
        "Name" : "Goblin",
        "HP" : 7,
        "DP": 15,
        "AP": random.randint(1,3),
        "GP" : random.randint(1,2),
        "SL" : 8,
    }
    return monster_stat_dict



def giant_rat_stats():
    monster_stat_dict = {
        "Name" : "Gaint Rat",
        "HP" : 5,
        "DP": 10,
        "AP": random.randint(1,2),
        "GP" : 0,
        "SL" : 6,
    }
    return monster_stat_dict



def giant_bat_stats():
    monster_stat_dict = {
        "Name" : "Gaint Bat",
        "HP" : 7,
        "DP": 20,
        "AP": 1,
        "GP" : 0,
        "SL" : 7,
    }
    return monster_stat_dict



def slime_stats():
    monster_stat_dict = {
        "Name" : "Slime",
        "HP" : 6,
        "DP": 15,
        "AP": 2,
        "GP" : random.randint(1, 10),
        "SL" : 9,
    }
    return monster_stat_dict




def guardian_of_Zargonud():
    monster_stat_dict = {
        "Name": """Guardian of Zar'gonud""",
        "HP": 11,
        "DP": 20,
        "AP": 2,
        "GP": random.randint(5, 15),
        "SL" : 9
    }
    return monster_stat_dict



def monster_actions_in_combat(stat_dict, monster_stat_dict, monster_effecting_player):
    print()
    print(monster_stat_dict["Name"])
    print(f"Health: {monster_stat_dict["HP"]}")

    monster_effecting_player = False

    monster_action = random.randint(1,monster_stat_dict["SL"])

    if monster_action < 5:
        stat_dict = monster_melee_attack(stat_dict, monster_stat_dict)
    elif monster_action >= 5 and monster_action < 7:
        monster_stat_dict = monster_doge_action(monster_stat_dict)
    elif monster_action >= 7 and monster_action < 10:
        mixed_dict = monster_slows_player(stat_dict, monster_stat_dict)
        stat_dict = mixed_dict[0]
        monster_effecting_player = mixed_dict[1]
    # add more action for monsters with better skills

    time.sleep(2)
    return stat_dict, monster_stat_dict, monster_effecting_player



def monster_melee_attack(stat_dict, monster_stat_dict):
    attack_power = monster_stat_dict["AP"]
    player_defensive_power = stat_dict["DP"]

    roll_to_hit = random.randint(1, 100)
    if roll_to_hit >= 95:
        attack_power *= 2
        print("!!Critical Hit!!")
    
    if roll_to_hit > player_defensive_power:
        stat_dict["CHP"] -= attack_power

        if stat_dict["CHP"] >0:
            print(f"The {monster_stat_dict["Name"]} hit you for {attack_power} point/s of damage.")
        else:
            print(f"The {monster_stat_dict["Name"]} kills you, it finished you off by dealing {attack_power} point/s of damage.")
    else:
        print(f"The {monster_stat_dict["Name"]} missed their attack!")

    return stat_dict



def monster_doge_action(monster_stat_dict):
    print(f"The {monster_stat_dict["Name"]} took the doge action!")
    monster_stat_dict["DP"] *= 2
    return monster_stat_dict



def monster_slows_player(stat_dict, monster_stat_dict):
    player_defensive_power = stat_dict["DP"]
    stamina_drain = 1

    roll_to_hit = random.randint(1, 100)
    if roll_to_hit >= 95:
        stamina_drain *= 2
        print("!!Critical Hit!!")

    if roll_to_hit > player_defensive_power:
        stat_dict["MSP"] -= stamina_drain
        stat_dict["CSP"] -= stamina_drain

        if stat_dict["MSP"] > 0:
            print(f"The {monster_stat_dict["Name"]} temporarily drained your Max and Current Stamina by {stamina_drain} point/s.")
        else:
            print(f"The {monster_stat_dict["Name"]} kills you, it finished you off by draining your Max Stamina to {stat_dict["MSP"]}.")
            stat_dict["CHP"] = 0
        
        if stat_dict["CSP"] <= -5:
            print(f"The {monster_stat_dict["Name"]} kills you, it finished you off by draining your current Stamina to -5 or below.")
            stat_dict["CHP"] = 0
    else:
        print(f"The {monster_stat_dict["Name"]} missed their attack!")

    return stat_dict, True