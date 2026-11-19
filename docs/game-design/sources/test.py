

print("\nWhere do you go? ")
print("1: East to CELLBLOCK")
print("2: West to GUARD ROOM")
print("3: North to Exit")
location = input().upper()

incorrect_input_counter = 0
while incorrect_input_counter < 2:
    if location != "1" and location != "2" and location != "W" and location != "E" and location != "WEST" and location != "EAST" and location != "CELLBLOCK" and location != "GUARD ROOM" and location != "N" and location != "3" and location != "NORTH" and location != "EXIT":
        location = input("Where do you go? ").upper()
        incorrect_input_counter += 1
    else:
        incorrect_input_counter = 5
    
if  location != "1" and location != "2" and location != "W" and location != "E" and location != "WEST" and location != "EAST" and location != "CELLBLOCK" and location != "GUARD ROOM" and location != "N" and location != "3" and location != "NORTH" and location != "EXIT":
    location = "1"
    
if location == "1" or location == "E" or location == "EAST" or location == "CELLBLOCK":
    location = "CELLBLOCK"
elif location == "2" or location == "W" or location == "WEST" or location == "GUARD ROOM":
    location = "GUARD ROOM"
elif location == "N" or location == "3" or location == "NORTH" or location == "EXIT":
    location = "Exit"



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


answer = question_with_multiple_answers("\nWhere do you go? \n1: East to CELLBLOCK \n2: West to GUARD ROOM \n3: North to EXIT","Where do you go? ", [
    "1", "2", "3", "N", "E", "W", "NORTH", "EAST", "WEST", "CELLBLOCK", "GUARD ROOM", "EXIT"
])
print(multiple_answer_decider(answer, [["1","E", "EAST", "CELLBLOCK"],["2", "W", "WEST", "GUARD ROOM"], ["3", "N", "NORTH", "EXIT"]], ["CELLBLOCK", "GUARD ROOM", "EXIT"]))
