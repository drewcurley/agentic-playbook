import pytest
from pytest import approx
from character import starting_stats, upgrade_stats, leveling_up, charcter_creator, veiw_character_sheet, starting_inventory, add_weapon_to_inventory, equipt_weapon, melee_attack, actions_in_combat, starting_spells, casting_spells_in_combat, basic_magic_missile, basic_healing, combat, add_trinket_to_inventory, using_tiny_stamina_potion, using_tiny_healing_potion
from monsters import goblin_stats
from character import save_game, load_game



def test_leveling_up():
    real_stat_dict = {
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

    stat_dict = leveling_up()

    assert real_stat_dict["MHP"] == stat_dict["MHP"]
    assert real_stat_dict["CHP"] == stat_dict["CHP"]
    assert real_stat_dict["MSP"] == stat_dict["MSP"]
    assert real_stat_dict["CSP"] == stat_dict["CSP"]
    assert real_stat_dict["MMP"] == stat_dict["MMP"]
    assert real_stat_dict["CMP"] == stat_dict["CMP"]
    assert real_stat_dict["PL"] == stat_dict["PL"]
    assert real_stat_dict["GP"] == stat_dict["GP"]
    assert real_stat_dict["AP"] == stat_dict["AP"]
    assert real_stat_dict["DP"] == stat_dict["DP"]
    assert real_stat_dict["EW"] == stat_dict["EW"]
    assert real_stat_dict["EA"] == stat_dict["EA"]
    pass

    

def test_save_and_load_game():
    with open("Runewell_rpg/saves/test_savefile", "w") as file: # clears the test save file
        pass

    stat_dict = starting_stats()
    stat_dict["Name"] = "Jim Bob"
    inventory_dict = starting_inventory()
    spell_dict = starting_spells()
    checkpoint = 1
    save_game(stat_dict, inventory_dict, spell_dict, checkpoint, "test_savefile") #writes data to the test save file
    mixed_dict = load_game("test_savefile") # reads data from test save file and formats it.

    new_stat_dict = mixed_dict[0]
    new_inventory_dict = mixed_dict[1]
    new_spell_dict = mixed_dict[2]
    new_checkpoint = mixed_dict[3]

    assert new_stat_dict == stat_dict
    assert new_inventory_dict == inventory_dict
    assert new_spell_dict == spell_dict
    assert new_checkpoint == checkpoint
    pass


pytest.main(["-v", "--tb=line", "-rN", __file__])