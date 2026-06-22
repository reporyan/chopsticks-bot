#120625
require 'rubygems'
require 'gosu'

WIDTH = 1280
HEIGHT = 720

HIGHLIGHT_THICKNESS = 5

BG_COLOUR = Gosu::Color::BLACK
BG2_COLOUR = Gosu::Color.new(0xFF331a00)
MAIN_COLOUR = Gosu::Color.new(0xFFff8000)
TEXT_COLOUR = Gosu::Color::WHITE
HIGHLIGHT_COLOUR = Gosu::Color::YELLOW
P1_COLOUR = Gosu::Color.new(0xFF000d3d)
P2_COLOUR = Gosu::Color.new(0xFF4a0101)

module ZOrder
  BACK, BACK_MID, HIGHLIGHT, MID, FRONT = *0..4
end

module Choices
    LL, LR, RL, RR, LR0, LR1, LR2, LR3, LR4, RL0, RL1, RL2, RL3, RL4 = *0..13
end

class Turn
    #initialise
    attr_accessor :parent, :p1l, :p1r, :p2l, :p2r, :turn_count, :turn_player, :parents, :children, :score, :branch_end, :from_choice
    
    def initialize
        #fingers
        @p1l = 1
        @p1r = 1
        @p2l = 1
        @p2r = 1

        #info
        @turn_count = 0
        @turn_player = 1 #whos turn is it to go

        #references
        @parents = []
        @children = []

        #algorithm - p1 wants 1, p2 wants -1
        @score = 0

        #branch end is whether this turn ends the game
        @branch_end = false

        #choice used to generate this move, for best move function to display
        @from_choice = -1
    end
end

class Button
    #initialise
    attr_accessor :x, :y, :w, :h, :colour, :text
    
    def initialize(x, y, w, h, colour, text)
        @x = x
        @y = y
        @w = w
        @h = h

        @colour = colour
        @text = text
    end
end

class ChopSticks < Gosu::Window
	def initialize
	    super WIDTH, HEIGHT
	    self.caption = "Chopsticks Solver"

        #general
        @turn_count = 0
        @p1wins = 0
        @p2wins = 0
        @draws = 0
        @choices = ["LL", "LR", "RL", "RR", "LR0", "LR1", "LR2", "LR3", "LR4", "RL0", "RL1", "RL2", "RL3", "RL4"]

        #labels
        @depth_input = 1
        @best_move = "N/A"
        @best_move_chain = "N/A"
        @gen_time = "N/A"

        @small_font = Gosu::Font.new(20)
        @button_font = Gosu::Font.new(30)
        @header_font = Gosu::Font.new(45)
        @finger_font = Gosu::Font.new(60)

        #mouse
        @mouse_down = false
        @mouse = false

        #instnatiate buttons
        @choice_buttons = []
        CreateButtons()

        #main
        puts("Program Started.")
        @turn = Turn.new()
        DisplayTurn(@turn)
    end

    def CreateButtons   
        i = 0
        while i < 7
            @choice_buttons << Button.new(190 + i * 60, 600, 50, 50, MAIN_COLOUR, "button")
            i += 1
        end
        while i < 14
            @choice_buttons << Button.new(190 + (i - 7) * 60, 660, 50, 50, MAIN_COLOUR, "button")
            i += 1
        end

        #dont need to define these beforehand
        @restart_button = Button.new(10, 660, 150, 50, MAIN_COLOUR, "RESTART")
        @subtract_button = Button.new(915, 545, 60, 60, MAIN_COLOUR, "")
        @add_button = Button.new(1115, 545, 60, 60, MAIN_COLOUR, "")
        @best_move_button = Button.new(810, 650, 450, 50, MAIN_COLOUR, "Find Best Move")
    end

    def MakeMove(turn, choice)
        #next turn generated from this turn

        #player 1 to move
        if(turn.turn_player == 1)
            #attack
            if(choice == Choices::LL)
                if(turn.p1l > 0 && turn.p2l > 0)#validate
                    turn.p2l = Attack(turn.p1l, turn.p2l)
                else
                    return false
                end
            elsif(choice == Choices::LR )
                if(turn.p1l > 0 && turn.p2r > 0)#validate
                    turn.p2r = Attack(turn.p1l, turn.p2r)
                else
                    return false
                end
            elsif(choice == Choices::RL)
                if(turn.p1r > 0 && turn.p2l > 0)#validate
                    turn.p2l = Attack(turn.p1r, turn.p2l)
                else
                    return false
                end
            elsif(choice == Choices::RR)
                if(turn.p1r > 0 && turn.p2r > 0)#validate
                    turn.p2r = Attack(turn.p1r, turn.p2r)
                else
                    return false
                end

            #transfer LR
            elsif(choice >= 4 && choice <= 8)
                if(turn.p1l > 0 && turn.p1r > 0)#validate
                    if(choice == Choices::LR0)
                        transfer_amount = 0
                    elsif(choice == Choices::LR1)
                        transfer_amount = 1
                    elsif(choice == Choices::LR2)
                        transfer_amount = 2
                    elsif(choice == Choices::LR3)
                        transfer_amount = 3
                    elsif(choice == Choices::LR4)
                        transfer_amount = 4
                    end

                    if(transfer_amount <= turn.p1l)#validate
                        #update turn to use new fingers
                        new_fingers = Transfer(turn.p1l, turn.p1r, transfer_amount)
                        turn.p1l = new_fingers[0]
                        turn.p1r = new_fingers[1]
                    else
                        return false
                    end
                else
                    return false
                end

            #transfer
            else
                if(turn.p1l > 0 && turn.p1r > 0)#validate
                    if(choice == Choices::RL0 && turn.p1l > 0 && turn.p1r > 0)
                        transfer_amount = 0
                    elsif(choice == Choices::RL1 && turn.p1l > 0 && turn.p1r > 0)
                        transfer_amount = 1
                    elsif(choice == Choices::RL2 && turn.p1l > 0 && turn.p1r > 0)
                        transfer_amount = 2
                    elsif(choice == Choices::RL3 && turn.p1l > 0 && turn.p1r > 0)
                        transfer_amount = 3
                    elsif(choice == Choices::RL4 && turn.p1l > 0 && turn.p1r > 0)
                        transfer_amount = 4
                    end

                    if(transfer_amount <= turn.p1r)#validate
                        #update turn to use new fingers
                        new_fingers = Transfer(turn.p1r, turn.p1l, transfer_amount)
                        turn.p1r = new_fingers[0]
                        turn.p1l = new_fingers[1]
                    else
                        return false
                    end
                else
                    return false
                end
            end
        
        #player 2 to move
        else
            #attack
            if(choice == Choices::LL)
                if(turn.p2l > 0 && turn.p1l > 0)#validate
                    turn.p1l = Attack(turn.p2l, turn.p1l)
                else
                    return false
                end
            elsif(choice == Choices::LR)
                if(turn.p2l > 0 && turn.p1r > 0)#validate
                    turn.p1r = Attack(turn.p2l, turn.p1r)
                else
                    return false
                end
            elsif(choice == Choices::RL)
                if(turn.p2r > 0 && turn.p1l > 0)#validate
                    turn.p1l = Attack(turn.p2r, turn.p1l)
                else
                    return false
                end
            elsif(choice == Choices::RR)
                if(turn.p2r > 0 && turn.p1r > 0)#validate
                    turn.p1r = Attack(turn.p2r, turn.p1r)
                else
                    return false
                end

            #transfer LR
            elsif(choice >= 4 && choice <= 8)
                if(turn.p2l > 0 && turn.p2r > 0)#validate
                    if(choice == Choices::LR0)
                        transfer_amount = 0
                    elsif(choice == Choices::LR1)
                        transfer_amount = 1
                    elsif(choice == Choices::LR2)
                        transfer_amount = 2
                    elsif(choice == Choices::LR3)
                        transfer_amount = 3
                    elsif(choice == Choices::LR4)
                        transfer_amount = 4
                    end

                    if(transfer_amount <= turn.p2l)#validate
                        #update turn to use new fingers
                        new_fingers = Transfer(turn.p2l, turn.p2r, transfer_amount)
                        turn.p2l = new_fingers[0]
                        turn.p2r = new_fingers[1]
                    else
                        return false
                    end
                else
                    return false
                end #if it cant do it it isnt a valid move
            #transfer
            else
                if(turn.p2l > 0 && turn.p2r > 0)#validate
                    if(choice == Choices::RL0)
                        transfer_amount = 0
                    elsif(choice == Choices::RL1)
                        transfer_amount = 1
                    elsif(choice == Choices::RL2)
                        transfer_amount = 2
                    elsif(choice == Choices::RL3)
                        transfer_amount = 3
                    elsif(choice == Choices::RL4)
                        transfer_amount = 4
                    end

                    if(transfer_amount <= turn.p2r)#validate
                        #update turn to use new fingers
                        new_fingers = Transfer(turn.p2r, turn.p2l, transfer_amount)
                        turn.p2r = new_fingers[0]
                        turn.p2l = new_fingers[1]
                    else
                        return false
                    end
                else
                    return false
                end
            end
        end

        #turn count
        turn.turn_count += 1

        #switch turn
        if(turn.turn_player == 1)
            turn.turn_player = 2
        else
            turn.turn_player = 1
        end
        

        #check whether the game state is done
        if(EndCheck(turn))
            turn.branch_end = true
        end

        return turn
    end

    def Attack(from, to)
        if(to + from < 5)
            return to + from
        else
            return 0
        end
    end

    def Transfer(from, to, amount)
        new_fingers = []

        new_fingers[0] = from - amount

        if(to + amount < 5)     
            new_fingers[1] = to + amount
        else
            new_fingers[1] = 0
        end

        return new_fingers
    end

    def EndCheck(turn)
        #this serves as evaluation of generation
        #longer game is better unless it's a win
        if(turn.turn_player == 1)
            turn.score = -turn.turn_count #if this turn is player 1 then the evaluating turn is player 2
        else
            turn.score = turn.turn_count
        end

        if(turn.p1l == 0 && turn.p1r == 0)
            #p2 win
            turn.score = -1000 + turn.turn_count
            @p2wins += 1
            return true
        elsif(turn.p2l == 0 && turn.p2r == 0)
            #p1 win
            turn.score = 1000 - turn.turn_count
            @p1wins += 1
            return true
        else
            #turn player now represents next turn to go
            #remember this is called after turn switch
            i = 0
            while(i < turn.parents.length)
                if(SameTurn(turn, turn.parents[i]))
                    if(turn.turn_player == 1)
                        #p2 tie
                        turn.score = -1000 + turn.turn_count
                    else
                        #p1 tie
                        turn.score = 1000 - turn.turn_count #maybe even increase 1000 so that other player tries to lose normally?
                    end
                    
                    @draws += 1
                    return true
                end
                i += 1
            end
        end

        return false
    end

    #game tree generation
    def GenerateGameTree(turn, depth)
        #time
        start_time = Time.now

        #this was used to reset all since they are set to N/A, but that doesn't happen anymore due to gameplay bug. Keeping it to be safe
        @turn_count = 0
        @p1wins = 0
        @p2wins = 0
        @draws = 0
        @gen_time = 0

        PathMove(turn, depth)

        puts("Total Turn Count: " + @turn_count.to_s())
        puts("P1 Wins: " + @p1wins.to_s())
        puts("P2 Wins: " + @p2wins.to_s())
        puts("Draws: " + @draws.to_s())
        puts("Gen Time: " + (Time.now - start_time).to_s())
        @gen_time = Time.now - start_time

        return turn
    end

    def PathMove(turn, depth)
        @turn_count += 1

        if(depth == 0)
            turn.branch_end = true
            return nil;
        end

        i = 0
        while i < 14
            if(i != 4 && i != 9)
                child_turn = Turn.new()

                child_turn.p1l = turn.p1l
                child_turn.p1r = turn.p1r
                child_turn.p2l = turn.p2l
                child_turn.p2r = turn.p2r
                child_turn.turn_count = turn.turn_count
                child_turn.turn_player = turn.turn_player
                child_turn.parents = turn.parents.clone
                child_turn.parents << turn

                #from choice
                child_turn.from_choice = i
                if(MakeMove(child_turn, i))
                    turn.children << child_turn
                    if(child_turn.branch_end == false) #only keep going if it isnt the end of the branch
                        PathMove(child_turn, depth - 1)
                    end
                end
            end

            i += 1
        end
    end

    def SameTurn(turn1, turn2)
        if(turn1.p1l == turn2.p1l && turn1.p1r == turn2.p1r && turn1.p2l == turn2.p2l && turn1.p2r == turn2.p2r && turn1.turn_player == turn2.turn_player)
            return true
        else
            return false
        end
    end

    #impotant for debugging
    def ShowGame()
        DisplayTurn(turn)

        i = 0
        while (i < 6)
            random = rand(turn.children.length)
            DisplayTurn(turn.children[random])
            turn = turn.children[random]
            i += 1
        end
    end

    #bot
    def Minimax(turn, depth)
        #return if end
        if(depth == 0 || turn.branch_end == true)
            return turn.score
        end

        #recursive
        if(turn.turn_player == 1)
            max_eval = -10000

            i = 0
            while i < turn.children.length
                eval = Minimax(turn.children[i], depth - 1)
                if(eval > max_eval)
                    max_eval = eval
                end
                i += 1
            end
            
            return max_eval
        else
            min_eval = 10000

            i = 0
            while i < turn.children.length
                eval = Minimax(turn.children[i], depth - 1)
                if(eval < min_eval)
                    min_eval = eval
                end
                i += 1
            end

            return min_eval
        end
    end

    def BestMove(turn, depth, root)
        #return if end
        if(turn == nil)
            puts("Nil Turn for Best Move")
            return nil
        elsif(depth == 0 || turn.branch_end == true)
            return nil
        end

        #recursive
        if(turn.turn_player == 1)
            max_eval = -10000
            max_child = -1

            i = 0
            while i < turn.children.length
                eval = Minimax(turn.children[i], depth - 1)
                if(eval > max_eval)
                    max_eval = eval
                    max_child = i
                end
                i += 1
            end

            puts(max_child.to_s())
            puts("Best Move: " + @choices[turn.children[max_child].from_choice])         
      
            if(root)
                @best_move = @choices[turn.children[max_child].from_choice]
            end

            return turn.children[max_child]
        else
            min_eval = 10000
            min_child = -1

            i = 0
            while i < turn.children.length
                eval = Minimax(turn.children[i], depth - 1)
                if(eval < min_eval)
                    min_eval = eval
                    min_child = i
                end
                i += 1
            end

            puts(max_child.to_s())
            puts("Best Move: " + @choices[turn.children[min_child].from_choice])

            if(root)
                @best_move = @choices[turn.children[min_child].from_choice]
            end

            return turn.children[min_child]
        end
    end

    #extra
    def DisplayTurn(turn)
        puts("--------")
        if(turn == nil)
            puts("Nil Turn for Display")
        else
            #info
            puts("Turn Count: " + turn.turn_count.to_s())
            puts("Score: " + turn.score.to_s())

            #fingers
            print("P2L: " + turn.p2l.to_s() + " ... ")
            puts("P2R: " + turn.p2r.to_s())
            print("P1L: " + turn.p1l.to_s() + " ... ")
            puts("P1R: " + turn.p1r.to_s())

            puts("Player " + turn.turn_player.to_s() + "'s Turn")
        end
    end

    def Restart
        @turn = Turn.new()

        @best_move = "N/A"
        @turn_count = 0
        @p1wins = 0
        @p2wins = 0
        @draws = 0
        @gen_time = 0
    end

    #drawing
    def DrawBG
        Gosu.draw_rect(0, 0, WIDTH, HEIGHT, BG_COLOUR, ZOrder::BACK, mode=:default)       
        Gosu.draw_rect(800, 10, 470, 700, BG2_COLOUR, ZOrder::BACK_MID, mode=:default)   
    end
    
    def DrawButtons()
        #choice buttons
        i = 0
        while i < @choice_buttons.length
            button = @choice_buttons[i]
            Gosu.draw_rect(button.x, button.y, button.w, button.h, button.colour, ZOrder::MID, mode=:default)
            @button_font.draw(@choices[i], button.x, button.y, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
            i += 1
        end

        #restart button
        button = @restart_button
        Gosu.draw_rect(button.x, button.y, button.w, button.h, button.colour, ZOrder::MID, mode=:default)
        @button_font.draw(button.text, button.x, button.y, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)

        #depth buttons
        button = @subtract_button
        Gosu.draw_rect(button.x, button.y, button.w, button.h, button.colour, ZOrder::MID, mode=:default)
        button = @add_button
        Gosu.draw_rect(button.x, button.y, button.w, button.h, button.colour, ZOrder::MID, mode=:default)

        #search button
        button = @best_move_button
        Gosu.draw_rect(button.x, button.y, button.w, button.h, button.colour, ZOrder::MID, mode=:default)
        @button_font.draw(button.text, button.x, button.y, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
    end

    def DrawTurn()
        if (@turn == nil)
            return
        end

        #header
        @header_font.draw("Player To Move: " + @turn.turn_player.to_s(), 200, 10, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @header_font.draw("Turns Passed: " + @turn.turn_count.to_s(), 200, 60, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)

        #fingers
        Gosu.draw_rect(200, 125, 400, 100, P2_COLOUR, ZOrder::BACK, mode=:default)
        Gosu.draw_rect(200, 425, 400, 100, P1_COLOUR, ZOrder::BACK, mode=:default)

        @finger_font.draw(@turn.p2l.to_s(), 250, 150, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @finger_font.draw(@turn.p2r.to_s(), 500, 150, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @finger_font.draw(@turn.p1l.to_s(), 250, 450, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @finger_font.draw(@turn.p1r.to_s(), 500, 450, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)

        #arrow
        @image = Gosu::Image.new("images/turn_arrow.png")
        if(@turn.turn_player == 1)         
            @image.draw(610, 425, ZOrder::FRONT)
        else
            @image.draw(610, 125, ZOrder::FRONT)
        end     
    end

    #bot stuff
    def DrawBot
        @header_font.draw("Best Move: " + @best_move.to_s(), 925, 50, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @header_font.draw("Search Depth:", 925, 450, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @header_font.draw(@depth_input.to_s(), 1025, 550, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @small_font.draw("Best Move Chain: " + @best_move_chain.to_s(), 825, 110, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)

        #gen stats
        @small_font.draw("Gen Turns: " + @turn_count.to_s(), 825, 135, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @small_font.draw("P1 Gen Wins: " + @p1wins.to_s(), 825, 160, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @small_font.draw("P2 Gen Wins: " + @p2wins.to_s(), 825, 185, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @small_font.draw("Gen Draws: " + @draws.to_s(), 825, 210, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        @small_font.draw("Gen Time: " + @gen_time.to_s(), 825, 235, ZOrder::FRONT, 1.0, 1.0, TEXT_COLOUR)
        
        if(@depth_input >= 10)
            @small_font.draw("WARNING: Depth > 10 can calculate slowly (>1min)", 810, 625, ZOrder::FRONT, 1.0, 1.0, Gosu::Color::RED)
        end

        @image = Gosu::Image.new("images/subtract.png")
        @image.draw(920, 550, ZOrder::FRONT)
        @image = Gosu::Image.new("images/add.png")
        @image.draw(1120, 550, ZOrder::FRONT)
    end

    def QueryButtons
        i = 0
        while i < @choice_buttons.length
            if(ButtonHovered(@choice_buttons[i]))
                if(@mouse_down)
                    #first, store this as parent
                    @turn.parents << @turn.clone

                    #then do rest
                    MakeMove(@turn, i)
                    puts("@turn parents: " + @turn.parents.length.to_s())
                    @best_move = "N/A"
                    @turn_count = 0
                    @p1wins = 0
                    @p2wins = 0
                    @draws = 0
                    @gen_time = 0
                    
                    DisplayTurn(@turn)
                end
            end
            i += 1
        end

        if(ButtonHovered(@restart_button))
            if(@mouse_down)
                Restart()
                
                DisplayTurn(@turn)
            end
        end

        if(ButtonHovered(@subtract_button))
            if(@mouse_down)
                if(@depth_input > 1)
                    @depth_input -= 1
                end
            end
        end

        if(ButtonHovered(@add_button))
            if(@mouse_down)
                @depth_input += 1
            end
        end

        if(ButtonHovered(@best_move_button))
            if(@mouse_down)
                #can't pass in @turn because it gets modified since it is a pointer...
                #delete references since they get generated anyway, avoids issues
                turn = @turn.clone
                turn.parents = @turn.parents.clone #duplicate or else it copies pointer
                turn.children = []

                turn = GenerateGameTree(turn, @depth_input)
                puts("game tree")
                DisplayTurn(turn)
                #have to use game tree child because it has children references

                #display chain of best moves
                @best_move_chain = ""
                root = true #if this is the root best move - used for displaying best move in UI
                i = 0
                while (i < @depth_input)
                    if(turn != nil)
                        turn = BestMove(turn, @depth_input - i, root)
                        root = false
                        if(turn != nil)
                            if(i < 5) #only display a few moves
                                @best_move_chain = @best_move_chain + @choices[turn.from_choice] + " -> "
                            end
                            DisplayTurn(turn)
                        end
                    end
                    i += 1
                end
            end
        end
    end

    def ButtonHovered(button)
        if(mouse_x >= button.x && mouse_x <= button.x + button.w && mouse_y >= button.y && mouse_y <= button.y + button.h)
            Gosu.draw_rect(button.x - HIGHLIGHT_THICKNESS, button.y - HIGHLIGHT_THICKNESS, button.w + 2 * HIGHLIGHT_THICKNESS, button.h + 2 * HIGHLIGHT_THICKNESS, HIGHLIGHT_COLOUR, ZOrder::HIGHLIGHT, mode=:default)     
            return true
        else
            #puts("nohover")
            return false
        end
    end

    #mouse check
    def update
        mouse_prev = @mouse
        @mouse = button_down?(Gosu::MS_LEFT)

        if(@mouse == true && mouse_prev == false)
            @mouse_down = true
        else
            @mouse_down = false
        end     
    end

    #master draw function
    def draw
        DrawBG()
        DrawButtons()
        DrawTurn()
        DrawBot()

        QueryButtons()
    end

    def needs_cursor?; true; end
end

ChopSticks.new.show if __FILE__ == $0