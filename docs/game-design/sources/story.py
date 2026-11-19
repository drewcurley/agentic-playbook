###This file contains all functions pretaining to the story of Runewell RPG###
import time
from character import starting_inventory, add_weapon_to_inventory, charcter_creator, starting_spells, veiw_character_sheet, leveling_up, add_trinket_to_inventory, add_armor_to_inventory, clear_screen, slow_print
import random


def intro():
    clear_screen()
    
    # ASCII art bird's eye view of the ashen valley surrounded by mountains
    slow_print("""
════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
                                              *** THE ASHEN VALLEY ***
                                                 (Bird's Eye View)
                                                      
        /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\    /^^^^\\
       /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\  /^^^^^^\\
      /^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\/^^^^^^^^\\
     /^^                                           Mountain Pass                                                  ^^\\
    /^^^^                                               |                                                        ^^^^\\
   /^^^^^^                                              |                                                       ^^^^^^\\
  /^^^^^^^^                                             |                                                      ^^^^^^^^\\
 /^^^^^^^^^^                                            |                                                     ^^^^^^^^^^\\
/^^^^^^^^^^^^                                           |                                                    ^^^^^^^^^^^│
│^^^^^^^^^^^^^^                                        /                                                   ^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                                     /                                                   ^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                    [Farm]          /            [Farm]                                ^^^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                   ┌─────┐         /            ┌─────┐                               ^^^^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                   │ ≈≈≈ │        /             │ ≈≈≈ │                               ^^^^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                   └─────┘       /              └─────┘                                ^^^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^              [Farm]            /                                                       ^^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^             ┌─────┐           /        [Farm]                                           ^^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^             │ ≈≈≈ │          |        ┌─────┐                                            ^^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^             └─────┘          |        │ ≈≈≈ │                                             ^^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                              |        └─────┘                                              ^^^^^^^^^^^^│
│^^^^^^^^^^^^^^^                              |                                                              ^^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ╔══════════════════════════┼══════════════════════════════════════════════════════════════╗ ^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║                          └───────┐                                                      ║ ^^^^^^^^^│
/^^^^^^^^^^^^^^^   ║                                  │                Outer Wall                            ║ ^^^^^^^^^|
│^^^^^^^^^^^^^^^   ║  ┌─┐    ┌───┐      ┌─┐      ┌───┐│    ┌─┐       ┌───┐      ┌─┐      ┌───┐    ┌─┐        ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║┌─┤░├─┐  │ ▒ │    ┌─┤▓├─┐    │ ░ ││  ┌─┤░├─┐     │ ▒ │    ┌─┤▓├─┐    │ ░ │  ┌─┤░├─┐      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║│ └─┘ │  └───┘    │ └─┘ │    └───┘│  │ └─┘ │     └───┘    │ └─┘ │    └───┘  │ └─┘ │      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║└─────┘     ┌─┐   └─────┘     ┌───┐  └─────┘          ┌─┐ └─────┘      ┌───┐└─────┘      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║     ┌───┐  │▓│      ┌─┐      │ ▒ │       ┌───┐       │░│      ┌─┐     │ ▒ │  ┌───┐      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║     │ ░ │  └─┘    ┌─┤░├─┐    └───┘       │ ░ │       └─┘    ┌─┤▓├─┐   └───┘  │ ░ │      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║     └───┘       ┌─┤ └─┘ ├─┐      ┌─┐     └───┘              │ └─┘ │          └───┘      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║        ┌─┐      │ └─────┘ │      │▓│   ╔═════════════════════════════════════════╗      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║        │░│      └─────────┘      └─┘   ║                                         ║      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║        └─┘          ┌───┐              ║              Inner Wall                 ║      ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║   ┌───┐      ┌─┐    │ ▒ │              ║     ┌─┐           ┌─────────────┐       ║  ┌─┐ ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║   │ ▒ │      │▓│    └───┘              ║   ┌─┤█├─┐     ┌───┤   ██████    ├───┐   ║  │▓│ ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║   └───┘      └─┘      ┌─┐              ║   │ └─┘ │     │   │   CASTLE    │   │   ║  └─┘ ║^^^^^^^^^^│
│^^^^^^^^^^^^^^^   ║                       │░│              ║   └─────┘     │   │    KEEP     │   │   ║ ┌───┐║^^^^^^^^^^|
│^^^^^^^^^^^^^^^   ║                       └─┘              ║        ┌─┐    │   │  ████████   │   │   ║ │ ░ │║^^^^^^^^^^/
│^^^^^^^^^^^^^^^   ║                                        ║        │▓│    └───┤             ├───┘   ║ └───┘║^^^^^^^^^/
│^^^^^^^^^^^^^^^   ║               ┌───┐          ┌─┐       ║        └─┘        └─────┬───────┘       ║   ┌─┐║^^^^^^^^/
│^^^^^^^^^^^^^^^   ║               │ ░ │          │▓│       ║                         │               ║   │▓│║^^^^^^^/
│^^^^^^^^^^^^^^^   ║               └───┘          └─┘       ║                         │               ║   └─┘║^^^^^^/
│^^^^^^^^^^^^^^^   ║                                        ║                         │               ║ ┌───┐║^^^^^/
│^^^^^^^^^^^^^^^   ║     ┌─┐          ┌───┐       ┌─┐       ╚═════════════════════════════════════════╝ │ ▒ ││^^^^/
│^^^^^^^^^^^^^^^   ║     │▓│          │ ▒ │       │░│              ┌───┐      ┌─┐      ┌───┐            └───┘║^^^/
│^^^^^^^^^^^^^^^   ║     └─┘          └───┘       └─┘              │ ░ │      │▓│      │ ▒ │                 ║^^/
│^^^^^^^^^^^^^     ║                                               └───┘      └─┘      └───┘                 ║^/
│^^^^^^^^^^^       ╚═════════════════════════════════════════════════════════════════════════════════════════╝/
 \\^^^^^^                                                                                              ^^^^^^/
  \\^^^^      ┌─────────────────────── LEGEND ───────────────────────┐                                  ^^^^/
   \\^^       │ ███ = Castle Keep     ║ = Walls        ┌─┐ = Houses  │                                   ^^/
    \\        │ ▓ = Towers            ≈ = Farms      ░ = Buildings   │                                    /
     \\       │ ▒ = Shops/Smithies    | = Path       █ = Major Keep  │                                   /
      \\      │ [Farm] = Farmsteads                                  │                                  /
       \\     └──────────────────────────────────────────────────────┘                                 /
        \\^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
         \\^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
          \\^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
""",0.0005)
    input("\n[Press enter to continue.] ")
    
    inventory_dict = starting_inventory()
    slow_print("""\nYou stand at the entrance of a grand ashen valley. The journey here has taken everything, you can't seem to recall why this was
so important in the first place.""")
    time.sleep(2)
    slow_print("""\nBut yet you continue down from the mountain pass and into the valley. Traveling on this jagged path you see more and more remnants
of what used to be a fairly large kingdom. Towers, homes, walls, and the keep have all been buried by ash and time. Forgotten by almost all 
living things. Birds, rodents, and beasts of all kind, seem to avoid this valley. """)
    time.sleep(3)
    slow_print("""\nThe peaceful silence is broken at first by just a few drops of rain, and soon the pouring rain is all you can hear. Stopping at a
bend in the path, you see before you the rain pouring off of a statue of a man that's been placed in the center of the road.""")
    time.sleep(2)
    slow_print("""\nThis statue has its arms raised to a "X". You almost miss it, but underneath the torn scraps of cloth that the statue's dressed in,
is a faintly glowing rune. The rune placed on the statue's chest glows a dim yellow. Getting closer to it, you notice it hums barely lound enough
to be heard over the rain. You feel compelled to touch it, as if this will tell you why you came so far.\n""")
    time.sleep(3)

    touch = yes_or_no_question("Do you touch the rune? (Y/N) ")

    clear_screen()
    
    if touch == "Y" or touch == "YES":
        slow_print("""\nAs your fingers rest upon the statue's chest, you feel a warmth emanating from the rune. Your eyes slip back into your head,
and you see a vision.""")
        time.sleep(1.5)
        slow_print("""\nA man not unlike the statue runs up this path, away from the kingdom. Too afraid to look back, he continues to run. He fumbles
for a dagger within his cloth, accidently drops it, and then keeps running. Whatever's chasing him is hidden from you, like it is being blocked
from your consciousness, like it is being blurred out. Whatever it is catches up to the man and gets in front of him. The man raises his arms to 
defend agaisnt a comming blow, and then the vision fades. Looking back on the statue you see the fear still etched into his face.""")
        time.sleep(4)
        slow_print("\nHeading onward, your eyes catch a glimpse of light from a very RUSTED DAGGER. ")

        dagger = yes_or_no_question("Do you take the dagger? (Y/N) ")

        clear_screen()

        if dagger == "Y" or dagger == "YES":
            slow_print("\nAfter handling the dagger it's clear that this was in fact the same one which the staute had dropped when he was still a man.")
            time.sleep(1)
            inventory_dict = add_weapon_to_inventory(inventory_dict, ["RUSTED DAGGER", 0, 1])
        else:
            slow_print("""\nYou decide against picking up the RUSTED DAGGER.""")
        
        time.sleep(0.75)
        slow_print("\nYou continue down the pathway.")
    else:
        slow_print("\nYou decide against touching weird statues and strange magic, and continue down the path.")
        dagger = "N"
    
    time.sleep(1.5)
    slow_print("""\nAfter about another hour of walking in the rain, you reach the base of the valley. The water combined with the ash has started to
pool and has become an acidic gray mud. Trudging forward you pass a few homesteads, farms, ranches, smithies. You soon reach the walls of the city, the
gate still cracked open. Over the gate an inscription reads “In aeternum cum diis” """)
    time.sleep(3)
    slow_print("""\nPast the gate lies the dead city, the mud slowly flowing inward. Walking through the outer distict of the city at the edge of your 
vision you see a figure slink behind a wall, eying you with curiosity. The figure follows you, always keeping it distance, always hiding just out
sight and in the shadows.\n""")
    time.sleep(2.5)
    call_out = yes_or_no_question("Do you call out to the figure? (Y/N) ")

    clear_screen()
    if call_out == "Y" or call_out == "YES":
        slow_print("\nYou shout into the shadows “Show yourself!”")

        if dagger == "Y" or dagger == "YES":
            time.sleep(1)
            slow_print("\nYou brandish the RUSTED DAGGER, readying yourself for a fight.")
            time.sleep(1)
            slow_print('''"RUSTED DAGGER" has been equipped.''')
        
        time.sleep(1)
        slow_print("""\nThe figure steps out from the shadows of a collapsed cobbler's shop. The figure's robes and hood, tattered and wet. Underneath
the mud you make out blue runic writings covering every inch of the figure's robes.""")
        time.sleep(2)
        slow_print("""\n“I mean you no harm.” The figure speaks in a feminine but tired rasp. She raises her arms to show she carries no weapons.""")
        time.sleep(1)
        slow_print("""\nAs she takes down her hood you see the face of an aged woman, her skin also bears the same blue runic writing but as tattoos. Her eyes
don't match. While her right eye is dark brown, her left eye has been replaced with a cracked lens which every few seconds flashes a dim blue as
a circle of runes illuminates. The lens is held in place by metal headbands which have been screwed into her skull.""")
        time.sleep(3)
        slow_print("""\n“My name is Kaelin Drah. I live here, I know what… I know who you are. To a degree.”""")
        time.sleep(1)
    else:
        slow_print("""\nYou continue onward ignoring the shadowy figure. After another hour of trudging through the mud and rain, you reach the inner
wall of the city. Its portcullis remains closed. The portcullis is too strong to break, and the gaps between the bars too small to squeeze through.
Althought the mud seems to flow just fine. You stare at it for a moment and then decide to look for another way into the inner city, when the
shadowy figure reveals themself.""")
        time.sleep(3.5)
        slow_print("""\nThe figure steps out from the shadows of a collapsed blacksmith's shop. The figure's robes and hood, tattered and wet. Underneath
the mud you make out blue runic writings covering every inch of the figure's robes.""")
        time.sleep(2)
        slow_print("""\n“You'll have to enter through the ruined prison.” The figure speaks in a feminine but tired rasp. She raises her arms to show she
carries no weapons.""")
        time.sleep(1.5)
        slow_print("""\nAs she takes down her hood you see the face of an aged woman, her skin also bears the same blue runic writing but as tattoos. Her eyes
don't match. While her right eye is dark brown, her left eye has been replaced with a cracked lens which every few seconds flashes a dim blue, as
a circle of runes illuminates. The lens is held in place by metal headbands which have been screwed into her skull.""")
        time.sleep(3)
        slow_print("""\n“My name is Kaelin Drah. I live here, I know what… I know who you are. To a degree.”""")
        time.sleep(1)
    
    stat_dict = charcter_creator()
    spell_dict = starting_spells()

    if dagger == "N" or dagger == "NO":
        stat_dict["AP"] = 0
    else:
        stat_dict["EW"] = "RUSTED DAGGER"


    time.sleep(1.5)
    clear_screen()
    slow_print("""Kaelin Drah hands you a small stone with a blue rune circle inscribed into it. "So this is you then." She whispers.""")
    time.sleep(1)
    slow_print("""\nLooking at the stone, it lights up and holographic text appears floating above it.""")
    time.sleep(1)
    print()
    print()
    veiw_character_sheet(stat_dict, inventory_dict, spell_dict)
    slow_print('''\n"I know why you're here and what you're looking for." Kaelin Drah rasps. "You'll find it in the inner city, but the only way in is
through the ruined prison."''')
    time.sleep(1.25)
    slow_print('''\nKaelin starts to lead you, to what you can only assume is the ruined prison.''')
    time.sleep(0.75)
    slow_print('''\n"You won't have to worry about any prisoners, they all escaped or died a long time ago with the rest of the city. Although the rat
constructs might be back."''')
    time.sleep(1.25)

    dialouge1 = 0
    option_1 = False
    option_2 = False
    option_3 = False
    option_5 = False
    option_4 = False

    heard_dialouge_counter = 0

    while dialouge1 != "6":


        print()
        print("Dialogue options: (Tip: Use the number index to choose what to say.)")
        print("-" * 40)
        print('1: "Rat constructs?"')
        print('2: "This valley, what happened?"')
        print('''3: "Earlier you said you knew who I was, but didn't know my name?"''')

        if option_3 == True:
            print('''4: "Come back? I've never been here before?"''')
            print('5: "Others? What do you mean?"')
            print('6: Quit [Say Nothing]')
        else:
            print('4: Quit [Say Nothing]')

        print("-" * 40)
        dialouge1 = input()
        print()

        if option_3 == False:
            incorrect_input_counter = 0
            while incorrect_input_counter < 2:
                if dialouge1 != "1" and dialouge1 != "2" and dialouge1 != "3" and dialouge1 != "4":
                    dialouge1 = input("Invaild input, please try again. ")
                    print()
                    incorrect_input_counter += 1
                else:
                    incorrect_input_counter = 5

            if dialouge1 != "1" and dialouge1 != "2" and dialouge1 != "3" and dialouge1 != "4":
                dialouge1 = "6"

            if dialouge1 == "4":
                dialouge1 = "6"
        else:
            incorrect_input_counter = 0
            while incorrect_input_counter < 2:
                if dialouge1 != "1" and dialouge1 != "2" and dialouge1 != "3" and dialouge1 != "4" and dialouge1 != "5" and dialouge1 != "6":
                    dialouge1 = input("Invaild input, please try again. ")
                    print()
                    incorrect_input_counter += 1
                else:
                    incorrect_input_counter = 5

            if dialouge1 != "1" and dialouge1 != "2" and dialouge1 != "3" and dialouge1 != "4" and dialouge1 != "5" and dialouge1 != "6":
                dialouge1 = "4"

        clear_screen()
        if dialouge1 == "1":
            option_1 = True
            heard_dialouge_counter += 1
            slow_print('''"They started appearing shortly after the decay started. They were the first constructs that appeared. They're basically giant rats.
except for the fact that They don't behave like rats at all, they show no fear, not even towards fire. I impaled one once, and it kept crawling forward,
impaling itself more to try to bite me."''')
            time.sleep(2.25)
            slow_print('''\n"You would think that they would've died out by now, because there's no food for them in the valley. But still they persist."''')
            time.sleep(1)
            input("[Press enter when you wish to continue.] ")
    
        elif dialouge1 == "2":
            option_2 = True
            heard_dialouge_counter +=1
            slow_print('''"This city was once known as the city of Tyrus. It was a bustling city, well protected by the mountains, blessed by the gods. The city
was growing fast and the king's court started looking for ways to house the increasing population inside the valley."''')
            time.sleep(2)
            slow_print('''\n"It was brought to the attention of the king's court that this city rests on the ruins of a much more ancient civilization. So the King
started looking for this civilization, sending workers and his best knights to dig underneath our very feet."''')
            time.sleep(2)
            slow_print('''\n"They soon found a large system of narrow caves that ran on for miles in multiple directions. The deepest caves eventually led them to
a sealed door."''')
            time.sleep(1.25)
            slow_print('''\n"Instead of being content with the caverns, the king's court urged their forces to break down the door. The kingdom's strongest knights,
smartest wizards, and most skilled thieves could only crack the seal."''')
            time.sleep(1.5)
            slow_print('''\n"Then came the decay, an ancient curse from the door. It turned everything living to ash as it spread. The only organic things unharmed were the
constructs that started to appear, and those that used powerful magic to stave off the decay."''')
            time.sleep(1.5)
            input("[Press enter when you wish to continue.] ")

        elif dialouge1 == "3":
            option_3 = True
            slow_print('''"Ah it's not my place to tell you that. But you're not the first to have come back here."''')
            time.sleep(0.75)
            input("[Press enter when you wish to continue.] ")
        
        elif dialouge1 == "4":
            option_4 = True
            slow_print('''"Well, not all of you has been here before. But don't you feel it? It's calling to you. It's been singi… calling to you for a while
now. Don't you want to know why you've come so far, and given up so much?"''')
            time.sleep(1.5)
            input("[Press enter when you wish to continue.] ")

        elif dialouge1 == "5":
            option_5 = True
            slow_print('''"Patience, you'll find out soon enough."''')
            time.sleep(1)
            input("[Press enter when you wish to continue.] ")

        if option_1 == True and option_2 == True and option_3 == True and option_4 == True and option_5 == True:
            dialouge1 = "6"
        
        clear_screen()

            
    time.sleep(3)
    slow_print("\nAfter a short moment you arrive at a gaping hole in the inner wall of the city, the hole leads into the aforementioned prison.\n")
    time.sleep(1)

    if dagger == "Y" or dagger == "YES":
        slow_print('''"I see that you've found my husband's dagger, may it serve you well in there."''')
        if call_out == "N" or call_out == "NO":
            time.sleep(1)
            slow_print('''"RUSTED DAGGER" has been equipped.''')
            stat_dict["EW"] = "RUSTED DAGGER"
    else:
        slow_print('''"You don't have a weapon, you will need one." Kaelin looks around the entrance for a short bit. Turning over a skeleton she finds a broken
sword and hands it over to you. "This will have to do.\n"''')
        time.sleep(1.5)
        inventory_dict = add_weapon_to_inventory(inventory_dict, ["BROKEN SWORD", 0, 1])
        time.sleep(1)
        slow_print('''"BROKEN SWORD" has been equipped.''')
        stat_dict["AP"] = 1
        stat_dict["EW"] = "BROKEN SWORD"
    
    time.sleep(1)
    slow_print('''\n"Go on ahead, I'll meet you on the other side."''')
    time.sleep(2)

    clear_screen()
    checkpoint = 1
    return stat_dict, inventory_dict, spell_dict, checkpoint



def yes_or_no_question(question, inverse=False):

    answer = input(question).upper()

    incorrect_input_counter = 0
    while incorrect_input_counter < 2:
        if answer != "Y" and answer != "N" and answer != "YES" and answer != "NO":
            answer = input(question).upper()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5

    if inverse == False:
        if answer != "Y" and answer != "N" and answer != "YES" and answer != "NO":
            answer = "N"
    elif inverse:
         if answer != "Y" and answer != "N" and answer != "YES" and answer != "NO":
            answer = "Y"

    return answer



def the_inner_city(stat_dict, inventory_dict, spell_dict):
    stat_dict = leveling_up(stat_dict)
    clear_screen()
    veiw_character_sheet(stat_dict, inventory_dict, spell_dict)
    slow_print("""As you walk past the small court, Kaelin Drah stands by leaning on what used to be a training dummy. "I see you've made it through,
follow me." """)
    time.sleep(1.25)
    slow_print('''\nKaelin Drah leads you away from the inner wall and through the remains of the market. She goes through ruined storefronts and homes
avoiding the thick gray mud which continues to slowly flow towards the center of the city.''')
    time.sleep(1.5)
    slow_print('''\nThe sun slowly starts to disappear behind the mountains as you inch closer to the city's center. You catch glimpses of the royal keep.
It's of a gothic build, and looks to have three distinct chapels built into the sides, each one is 120 degrees offset from each other.
The keep also has the remnants of 5 towers that once had all reached towards the sky. Surrounding the keep is an additional wall with a
portcullis, and surrounding the wall a small moat with a broken bridge that now lies at the bottom of the moat. ''')
    time.sleep(3.75)
    slow_print('''\n“That was the place of the gods and government. Although this kingdom was led by a king, the king's court made all the final decisions.
They consisted of the regional dukes and lords. At the head of the court directly under the king were the prophets of the 3 gods.”''')
    time.sleep(2)
    slow_print('''\n“You'll have to go through the keep eventually if you wish to seek what you've come here for. ”''')
    time.sleep(0.75)
    slow_print('''\nKaelin Droh lights a torch which you don't remember seeing her pick up. The night sky is filled with stars and galaxies whose beauty
almost makes you stop and stare for a moment. The twin moons start their ascent into the sky, under their light and the light of Kaelin's
torch you make your way to the city's center. A large empty marketplace with spots for stands of all sorts. At the very center is a large
drain. It is clear that this is the lowest point in the city and the valley. The mud flows from all angles into this drain.''')
    time.sleep(4)
    slow_print('''\n“You must follow the flow of the mud into the drain. Down there you will have to pass through parts of the sewer system, and find your
way to the castle. In the castle you'll need to find the SCEPTER OF THE GODS.”''')
    time.sleep(1.5)
    slow_print('''\n“Before you go down though, I can offer you a few wares and items that you might find useful. For a price of course. I foresee that the
challenge ahead of you will take everything you've got void spawn.”''')
    time.sleep(1.5)

    diaglouge2 = ""

    option_1 = False
    option_2 = False
    option_3 = False
    option_4 = False
    option_5 = False
    option_6 = False
    option_7 = False
    
    first_time_buying = True

    while diaglouge2 != "8":
        print()
        print("-" * 40)
        print('''1: "You've called me "void spawn" twice now, what does it mean?" ''')
        print('2: "The 3 gods? Which pantheon was worshiped here?" ')
        print('''3: "Tell me more about this SCEPTER OF THE GODS."''')

        if "RUSTED DAGGER" in inventory_dict["Weapons"]:
            print('''4: "You mentioned that the RUSTED DAGGER which I carry was your husband's. If I may asked, how did he... become a statue?"''')
        else:
            print('''4: "There was a statue on the mountain pass that seemed off. Is that something to worry about?" ''')

        print('5: "I heard a voice within the prison helping me, was that you?"')
        print('6: "How have you survived out here for so long, does the decay not affect you?"')
        print('7: "You mentioned you some wares for sale?" [SHOP]')
        print('8: Quit')

        print("-" * 40)
        diaglouge2 = input()
        print()

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:
            if diaglouge2 != "1" and diaglouge2 != "2" and diaglouge2 != "3" and diaglouge2 != "4" and diaglouge2 != "5" and diaglouge2 != "6" and diaglouge2 != "7" and diaglouge2 != "8":
                diaglouge2 = input("Invaild input, please try again. ")
                print()
                incorrect_input_counter += 1
            else:
                incorrect_input_counter = 5

            if diaglouge2 != "1" and diaglouge2 != "2" and diaglouge2 != "3" and diaglouge2 != "4" and diaglouge2 != "5" and diaglouge2 != "6" and diaglouge2 != "7" and diaglouge2 != "8":
                diaglouge2 = "8"

        clear_screen()
        if diaglouge2 == "1":
            option_1 = True
            slow_print('''\n“It's what you are. That's all I can tell you. Besides the fact that you aren't fully human. But of course you knew that, right? ”''')
            time.sleep(1)
            input("[Press enter when you wish to continue.] ")

        elif diaglouge2 == "2":
            option_2 = True
            slow_print('''\n“Well it's an ancient version of the pantheon of Ter, before the Second Titan War. Of course there's Rovona, goddess of life, light,
and liberty. And Zar'gonud, god of death, darkness, and misery. But very few tales and legends mention a third god, older than the two most of the world
worships today. His name has been lost over the centuries. Some myths say he died, or that he abandoned this world. No matter what happened to him, he
used to be the god of time, of growth, and decay. ”''')
            time.sleep(3.5)
            input("[Press enter when you wish to continue.] ")

        elif diaglouge2 == "3":
            option_3 = True
            slow_print('''\n“The SCEPTER OF THE GODS, was one of the last creations of this city. It's said that the prophets of the three gods and their devoted
followers poured their life essences into it, trying to create something to hold back the spreading decay.”''')
            time.sleep(1.75)
            slow_print('''\n“They attempted to create another door like the one they had opened. They wanted the scepter to be the key so they could eventually
open the door again, once they had found the strongest mages in all of Ter.”''')
            time.sleep(1.5)
            slow_print('''\n“As another layer of protection they created a golem to stand guard over that door. But it failed horribly, the golem was mistakenly
advised that anyone not holding the staff was to be killed. And kill it did. Everyone within the castle's walls were dead within hours.
It was the final event that sealed this kingdom's fate. The scepter is the key through the first door, and the key to getting past the
golem.”''')
            time.sleep(3)
            input("[Press enter when you wish to continue.] ")
        
        elif diaglouge2 == "4":
            option_4 = True
            slow_print('''\n“Ah my husband. He snuck into the castle looking for gold, but was spotted by the golem. He was able to shake it off pretty good, and
we thought we had lost it. All he had to do was get out of the valley, but he wasn't quick enough.”''')
            time.sleep(1.75)
            input("[Press enter when you wish to continue.] ")
        
        elif diaglouge2 == "5":
            option_5 = True
            slow_print('''\n“I didn't say anything to you, no...”''')
            time.sleep(1)

        
        elif diaglouge2 == "6":
            option_6 = True
            slow_print('''\n“Oh it does. I've managed to slow it through different magical means, potions, spells, my tattoos. And I don't spend all my time here
in the valley. I do venture out now and again.”''')
            time.sleep(1.25)
            input("[Press enter when you wish to continue.] ")
        
        elif diaglouge2 == "7":
            option_7 = True
            slow_print("\nTake a look!")
            time.sleep(2)
            mixed_dict = kealins_shop(stat_dict, inventory_dict, spell_dict, first_time_buying)
            stat_dict = mixed_dict[0]
            inventory_dict = mixed_dict[1]


        if option_1 == True and option_2 == True and option_3 == True and option_4 == True and option_5 == True and option_6 == True and option_7 == True:
            diaglouge2 = "8"
        
        clear_screen()
    
    time.sleep(1)
    slow_print('''\nKaelin then directs you to the large grate in the center of the market place, where all the mud flows into. She opens a circular gate in
the middle and drops a rope down for you. "Good Luck, down there." ''')
    time.sleep(2.25)

    clear_screen()
    checkpoint = 3
    return stat_dict, inventory_dict, spell_dict, checkpoint



def kealins_shop(stat_dict, inventory_dict, spell_dict, first_time_buying=False):
    clear_screen()
    buy_choice = None

    while buy_choice != "6":
        print("." * 90)
        print("                                 ..Kaelin's Shop..\n")
        time.sleep(0.01)
        print(f"{stat_dict["Name"]}'s Gold: {stat_dict["GP"]}")
        print("What do you buy? ")
        print("1: TINY HEALING POTION |Price: 15")
        print("2: TINY STAMINA POTION |Price: 10")
        print("3: TINY MANA POTION    |Price: 10")
        print("4: PADDED ARMOR        |Price: 10  |Defensive Power: 13")
        print("5: [VEIW Character Sheet]")
        print("6: Quit\n")

        buy_choice = input().upper()

        incorrect_input_counter = 0
        while incorrect_input_counter < 2:
            if buy_choice != "1" and buy_choice != "2" and buy_choice != "3" and buy_choice != "4" and buy_choice != "5" and buy_choice != "6" and buy_choice != "TINY HEALING POTION" and buy_choice != "TINY STAMINA POTION" and buy_choice != "TINY MANA POTION" and buy_choice != "PADDED ARMOR" and buy_choice != "QUIT" and buy_choice != "VEIW":
                buy_choice = input("Invaild input, please try again. ")
                print()
                incorrect_input_counter += 1
            else:
                incorrect_input_counter = 5

            if buy_choice != "1" and buy_choice != "2" and buy_choice != "3" and buy_choice != "4" and buy_choice != "5" and buy_choice != "6" and buy_choice != "TINY HEALING POTION" and buy_choice != "TINY STAMINA POTION" and buy_choice != "TINY MANA POTION" and buy_choice != "PADDED ARMOR" and buy_choice != "QUIT" and buy_choice != "VEIW":
                buy_choice = "6"


        if buy_choice == "1" or buy_choice == "TINY HEALING POTION":
            if stat_dict["GP"] >= 15:
                stat_dict["GP"] -= 15
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY HEALING POTION", 5, 1])
                time.sleep(1)
            else:
                slow_print('Not enough funds...')
                time.sleep(1)

        elif buy_choice == "2" or buy_choice == "TINY STAMINA POTION":
            if stat_dict["GP"] >= 10:
                stat_dict["GP"] -= 10
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY STAMINA POTION", 5, 1])
                time.sleep(1)
            else:
                slow_print('Not enough funds...')
                time.sleep(1)

        elif buy_choice == "3" or buy_choice == "TINY MANA POTION":
            if stat_dict["GP"] >= 10:
                stat_dict["GP"] -= 10
                inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY MANA POTION", 5, 1])
                time.sleep(1)
            else:
                slow_print('Not enough funds...')
                time.sleep(1)

        elif buy_choice == "4" or buy_choice == "PADDED ARMOR":
            if stat_dict["GP"] >= 10:
                stat_dict["GP"] -= 10
                inventory_dict = add_armor_to_inventory(inventory_dict, ["PADDED ARMOR", 10, 13])
                time.sleep(1)

        elif buy_choice == "5" or buy_choice == "VEIW":
            veiw_character_sheet(stat_dict, inventory_dict, spell_dict)

        elif buy_choice == "QUIT":
            buy_choice = "6"
        
        clear_screen()


    if first_time_buying == True:
        first_time_buying = False
        slow_print('''"Thanks for the business, since its your first time buying I'll be nice and throw in an extra potion for free."''')
        chance = random.randint(1,10)
        if chance < 5:
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY HEALING POTION", 5, 1])
        elif chance < 8:
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY STAMINA POTION", 5, 1])
        else:
            inventory_dict = add_trinket_to_inventory(inventory_dict, ["TINY MANA POTION", 5, 1])
        time.sleep(1)
    
    clear_screen()
    return stat_dict, inventory_dict, spell_dict



def question_with_multiple_answers(question, question_repeated, answer_list, incorrect= "1"):
    print(question)
    answer = input().upper()

    incorrect_input_counter = 0

    while incorrect_input_counter < 2:
        if answer not in answer_list:
            answer = input(question_repeated).upper()
            incorrect_input_counter += 1
        else:
            incorrect_input_counter = 5
    
    if answer not in answer_list:
        answer = incorrect

    return answer



def multiple_answer_decider(answer, choice_list, decision_list):
    for i in range(len(choice_list)):
        if answer in choice_list[i]:
            decision = decision_list[i]

    return decision