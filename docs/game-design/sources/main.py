### This is the file the game runs on. If you want to test my program do it through this file!!!###
from character import veiw_character_sheet, save_game, load_game
import time
from story import intro, the_inner_city, yes_or_no_question
from exploration import tutorial_dungeon_the_ruined_prison, dungeon1_the_sewers, clear_screen, slow_print
import os
import json


def main(do_continue=None):
    checkpoint = 0
    stat_dict = {"CHP": 0}

    if do_continue == None:
        filename = main_menu()
        clear_screen()
    
    if filename != None:

        mixed_dict = load_game(filename)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        spell_dict = mixed_dict[2]
        checkpoint = mixed_dict[3]


    if checkpoint == 0 and filename != None:
        mixed_dict = intro()
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        spell_dict = mixed_dict[2]
        checkpoint = mixed_dict[3]


    if checkpoint == 1 and filename != None:
        save_game(stat_dict, inventory_dict, spell_dict, checkpoint, filename)
        mixed_dict = tutorial_dungeon_the_ruined_prison(stat_dict, inventory_dict, spell_dict)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        spell_dict = mixed_dict[2]
        checkpoint = mixed_dict[3]
    

    if stat_dict["CHP"] > 0 and checkpoint == 2 and filename != None:
        save_game(stat_dict, inventory_dict, spell_dict, checkpoint, filename)
        mixed_dict = the_inner_city(stat_dict, inventory_dict, spell_dict)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        spell_dict = mixed_dict[2]
        checkpoint = mixed_dict[3]
    


    if stat_dict["CHP"] > 0 and checkpoint == 3 and filename != None:
        save_game(stat_dict, inventory_dict, spell_dict, checkpoint, filename) 
        mixed_dict = dungeon1_the_sewers(stat_dict, inventory_dict, spell_dict)
        stat_dict = mixed_dict[0]
        inventory_dict = mixed_dict[1]
        spell_dict = mixed_dict[2]
        checkpoint = mixed_dict[3]
    


    if stat_dict["CHP"] > 0 and filename != None: 
        print('''Thanks for playing the Demo for Runewell RPG! I hope you enjoyed!''')
        time.sleep(2)
        veiw_character_sheet(stat_dict, inventory_dict, spell_dict)

    pass

def main_menu():
    clear_screen()
    print("=" * 50)
    print("🌌 Welcome to Runewell RPG 🌌".center(50))
    print("=" * 50)
    print("\nChoose your destiny:")
    print("  1. 🧙 Start New Adventure")
    print("  2. 📖 Load Saved Journey")
    print("  3. 🛠 Settings")
    print("  4. ❌ Exit")
    print("\n" + "=" * 50)

    choice = input("Enter your selection (1-4): ").strip()

    if choice == "1":
        slow_print("\nSummoning your destiny...")
        time.sleep(1)
        filename = choose_save_file("new")

        if filename == None:
            filename = main_menu()

    elif choice == "2":
        slow_print("\nRetrieving ancient memories...")
        time.sleep(1)
        filename = choose_save_file("old")

        if filename == None:
            filename = main_menu()

    elif choice == "3":
        slow_print("\nOpening arcane preferences...")
        time.sleep(1)
        Game_settings()
        filename = main_menu()

    elif choice == "4":
        slow_print("\nFarewell, brave soul...")
        time.sleep(1)
        clear_screen()
        filename = None
    else:
        slow_print("\n!! Invalid selection. Please choose wisely!!")
        time.sleep(1.5)
        filename = main_menu()

    return filename



def choose_save_file(new_or_old):
    clear_screen()

    if new_or_old == "new":
        slow_print("\n Which save file would you like to use? (Using a file already in use will overwrite it.)\n")
    else:
        slow_print("\n Which save file would you like to use? (Using a empty file will start a new game.)\n")

    file_path1 = "saves/savefile1.txt"
    file_path2 = "saves/savefile2.txt"
    file_path3 = "saves/savefile3.txt"

    if os.path.getsize(file_path1) > 75:

        with open(file_path1, "r") as file:
            raw_data = file.read()
            save_data = json.loads(raw_data)

        checkpoint = save_data["checkpoint"]
        stat_dict = save_data["stat_dict"]

        location = checkpoint_location(checkpoint)

        print(f"File 1:  {stat_dict["Name"]} Location: {location}")

    else:
        print("File 1: [NEW GAME]")
    
    if os.path.getsize(file_path2) > 75:

        with open(file_path2, "r") as file:
            raw_data = file.read()
            save_data = json.loads(raw_data)

        checkpoint = save_data["checkpoint"]
        stat_dict = save_data["stat_dict"]

        location = checkpoint_location(checkpoint)

        print(f"File 2:  {stat_dict["Name"]} Location: {location}")

    else:
        print("File 2: [NEW GAME]")
    
    if os.path.getsize(file_path3) > 75:

        with open(file_path3, "r") as file:
            raw_data = file.read()
            save_data = json.loads(raw_data)

        checkpoint = save_data["checkpoint"]
        stat_dict = save_data["stat_dict"]

        location = checkpoint_location(checkpoint)

        print(f"File 3:  {stat_dict["Name"]} Location: {location}")

    else:
        print("File 3: [NEW GAME]")
    
    print("|4: QUIT ❌|")

    file_choice = input().upper()

    incorrect_input_counter = 0
    while incorrect_input_counter < 2:
        if file_choice != "1" and file_choice != "2" and file_choice != "3" and file_choice != "4" and file_choice != "QUIT":
            location = input("""Type the number for which file you wish to use or type "QUIT" or "4" to quit. """).upper()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if file_choice != "1" and file_choice != "2" and file_choice != "3" and file_choice != "4" and file_choice != "QUIT":
        file_choice = "4"
    
    if file_choice == "1":
        filename = "savefile1"
    
    elif file_choice == "2":
        filename = "savefile2"
    
    elif file_choice == "3":
        filename = "savefile3"
    
    elif file_choice == "4" or file_choice == "QUIT":
        filename = None

    if new_or_old == "new" and filename != None:
        save_game("", "", "", 0, filename)

    return filename



def Game_settings():
    clear_screen()
    slow_print("\n Game settings not included in the Runewell Demo build.")
    time.sleep(1.5)
    pass



def checkpoint_location(checkpoint):

    if checkpoint == 0:
        location = "The Outer City"

    elif checkpoint == 1:
        location = "The Ruined Prison"

    elif checkpoint == 2:
        location = "The Inner City"

    elif checkpoint == 3:
        location = "The Sewers of Tyrus"

    elif checkpoint == 4:
        location = "The Crypts of Zargonud"


    return location



def death_menu():
    time.sleep(3)
    clear_screen()
    slow_print("\n Game Over: You Died")
    time.sleep(3)

    do_you_wish_to_continue = yes_or_no_question("\nDo you wish to continue from the last checkpoint? ")

    if do_you_wish_to_continue == "Y" or do_you_wish_to_continue == "YES":

        main(do_you_wish_to_continue)
    else:
        slow_print("Goodbye...")
        time.sleep(1)
        clear_screen()
    pass







if __name__ == "__main__":
    main()