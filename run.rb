require 'pg'

instructions = gets.chomp
instructions = instructions.split(/}[[:space:]]*{/)
puts instructions.class.name
puts instructions
puts eval(instructions[0])
puts eval(instructions[0]).class.name
puts eval(instructions[0])[eval(instructions[0]).keys[0]]
puts eval(instructions[0])[eval(instructions[0]).keys[0]].class.name


$allowed_actions = Array.new
$allowed_actions.push(:open)
$result = Array.new
$siy = 31536000 #seconds in a year
begin
    instructions.each do |i|
        i=eval(i)
        fname = i.keys[0]
        if fname==:open and $allowed_actions.include?(fname)
            database = i[:database]
            login = i[:login]
            password = i[:password]
            if login=="init"
                $allowed_actions = Array.new
                $allowed_actions.push(:leader)
            elsif login=="app"
                $allowed_actions.delete(:open)
                $allowed_actions.delete(:leader)
                $allowed_actions.push(:support)
                $allowed_actions.push(:protest)
                $allowed_actions.push(:upvote)
                $allowed_actions.push(:downvote)
                $allowed_actions.push(:actions)
                $allowed_actions.push(:projects)
                $allowed_actions.push(:votes)
                $allowed_actions.push(:trolls)
            end
            $db = PG.connect :dbname => database, :user => login, :password => password
            $result.push("{\"status\": \"OK\"}")
        elsif fname==:leader and $allowed_actions.include?(fname)
            $db.exec "INSERT INTO ids VALUES(MAX(ids.id)+1);"
            $db.exec "INSERT INTO Member VALUES(MAX(ids.id), #{i[fname][:password]}, 1, #{i[fname][:timestamp]}, 0, 0);"
            $result.push("{\"status\": \"OK\"}")
        elsif fname==:support and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id FROM Member WHERE id=#{i[fname][:member]};"
            if tmp.length==0
                #there is no member, so we create one
                $db.exec "INSERT INTO Member VALUES(#{i[fname][:member]}, #{i[fname][:password]}, 0, #{i[fname][:timestamp]}, 0, 0);"
            end
            tmp = $db.exec "SELECT id, password FROM Member WHERE id=#{i[fname][:member]} AND password=#{i[fname][:password]};"
            if tmp.length>0 and tmp[0]['last_activity']-i[fname][:timestamp] > $siy
                #password matches and is not frozen
                tmp1 = $db.exec "SELECT pid, timestamp FROM Project WHERE pid=#{i[fname][:project]} AND timestamp<>#{i[fname][:timestamp]};"
                if tmp1.length>0
                    #there already is the project
                    $db.exec "INSERT INTO Action VALUES(MAX(Action.aid)+1, #{i[fname][:project]}, #{i[fname][:timestamp]}, 1, 0, 0);"
                    $result.push("{\"status\": \"OK\"}")
                else
                    #there is no such project
                    #we create one
                    $db.exec "INSERT INTO Project VALUES(#{i[fname][:project]}, #{i[fname][:timestamp]}, #{i[fname][:authority]});"
                    #we create action
                    $db.exec "INSERT INTO Action VALUES(MAX(Action.aid)+1, #{i[fname][:project]}, #{i[fname][:timestamp]}, 1, 0, 0);"
                    $result.push("{\"status\": \"OK\"}")
                end
            else
                #password does not match
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:protest and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id FROM Member WHERE id=#{i[fname][:member]};"
            if tmp.length==0
                #there is no member, so we create one
                $db.exec "INSERT INTO Member VALUES(#{i[fname][:member]}, #{i[fname][:password]}, 0, #{i[fname][:timestamp]}, 0, 0);"
            end
            tmp = $db.exec "SELECT id, password FROM Member WHERE id=#{i[fname][:member]} AND password=#{i[fname][:password]};"
            if tmp.length>0 and tmp[0]['last_activity']-i[fname][:timestamp] > $siy
                #password matches and is not frozen
                tmp1 = $db.exec "SELECT pid, timestamp FROM Project WHERE pid=#{i[fname][:project]} AND timestamp<>#{i[fname][:timestamp]};"
                if tmp1.length>0
                    #there already is the project
                    $db.exec "INSERT INTO Action VALUES(MAX(Action.aid)+1, #{i[fname][:project]}, #{i[fname][:timestamp]}, 0, 0, 0);"
                    $result.push("{\"status\": \"OK\"}")
                else
                    #there is no such project
                    #we create one
                    $db.exec "INSERT INTO Project VALUES(#{i[fname][:project]}, #{i[fname][:timestamp]}, #{i[fname][:authority]});"
                    #we create action
                    $db.exec "INSERT INTO Action VALUES(MAX(Action.aid)+1, #{i[fname][:project]}, #{i[fname][:timestamp]}, 0, 0, 0);"
                    $result.push("{\"status\": \"OK\"}")
                end
            else
                #password does not match
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:upvote and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id FROM Member WHERE id=#{i[fname][:member]};"
            if tmp.length == 0
                #we create a member, fi it does not exist
                $db.exec "INSERT INTO Member VALUES(#{i[fname][:member]}, #{i[fname][:password]}, 0, #{i[fname][:timestamp]}, 0, 0);"
            end
            tmp = $db.exec "SELECT id, password, timestamp FROM Member WHERE id=#{i[fname][:member]} AND password=#{i[fname][:password]};"
            if tmp.length > 0 and i[fname][:timestamp]-tmp[0]['timestamp']<$siy
                #the password matches and is not frozen
                tmp = $db.exec "SELECT aid FROM Action WHERE aid=#{i[fname][:action]};"
                if tmp.length > 0
                    #the actions already exists
                    tmp = $db.exec "SELECT Votes.Memberid, Votes.Actionid FROM Votes WHERE Votes.Memberid=#{i[fname][:member]} AND Votes.Actionid=#{i[fname][:action]};"
                    if tmp.length == 0
                        $db.exec "INSERT INTO Votes VALUES(#{i[fname][:member]}, #{i[fname][:action]}, 1, #{i[fname][:timestamp]});"
                        $db.exec "UPDATE Member SET upvotes=upvotes+1 WHERE id=#{i[fname][:member]};"
                    end
                    $result.push("{\"status\": \"OK\"}")
                else
                    $result.push("{\"status\": \"ERROR\"}")
                end
            else
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:downvote and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id FROM Member WHERE id=#{i[fname][:member]};"
            if tmp.length == 0
                #we create a member, fi it does not exist
                $db.exec "INSERT INTO Member VALUES(#{i[fname][:member]}, #{i[fname][:password]}, 0, #{i[fname][:timestamp]}, 0, 0);"
            end
            tmp = $db.exec "SELECT id, password, timestamp FROM Member WHERE id=#{i[fname][:member]} AND password=#{i[fname][:password]};"
            if tmp.length > 0 and i[fname][:timestamp]-tmp[0]['timestamp']<$siy
                #the password matches and is not frozen
                tmp = $db.exec "SELECT aid FROM Action WHERE aid=#{i[fname][:action]};"
                if tmp.length > 0
                    #the actions already exists
                    tmp = $db.exec "SELECT Votes.Memberid, Votes.Actionid FROM Votes WHERE Votes.Memberid=#{i[fname][:member]} AND Votes.Actionid=#{i[fname][:action]};"
                    if tmp.length == 0
                        $db.exec "INSERT INTO Votes VALUES(#{i[fname][:member]}, #{i[fname][:action]}, 0, #{i[fname][:timestamp]});"
                        $db.exec "UPDATE Member SET upvotes=upvotes+1 WHERE id=#{i[fname][:member]};"
                    end
                    $result.push("{\"status\": \"OK\"}")
                else
                    $result.push("{\"status\": \"ERROR\"}")
                end
            else
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:actions and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id, password, is_leader FROM Member WHERE id=#{i[fname][:member]}, password=#{i[fname][:password]}, is_leader=1;"
            if tmp.length>0
                text = "SELECT Action.aid, Action.type, Action.pid, Project.authority, Action.upvotes, Action.downvotes FROM Action, Project WHERE Project.pid=Action.pid"
                if i[fname][:type]=="support"
                    text+=", Action.type=1"
                elsif i[fname][:type]=="protest"
                    text+=", Action.type=0"
                end
                if i[fname][:project]
                    text+=", Action.pid=#{i[fname][:project]}"
                end
                if i[fname][:authority]
                    text+=", Project.authority=#{i[fname][:authority]}"
                end
                text+=" ORDER BY Action.aid INCR;"
                tmp = $db.exec(text)
                res = "{\"status\": \"OK\,\n\"data\":["
                tmp.each do |o|
                    o.each do |u|
                        res+=u
                        res+=", "
                    end
                    res.chomp(", ")
                    res+="\n"
                end
                res=res.chomp
                res+="]\n}"
                $result.push(res)
            else
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:projects and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id, password FROM Member WHERE id=#{i[fname][:member]}, AND password=#{i[fname][:password]};"
            if tmp.length > 0
                if i[fname][:authority]
                    tmp = $db.exec "SELECT pid, authority FROM Project WHERE authority=#{i[fname][:authority]} ORDER BY pid;"
                else
                    tmp = $db.exec "SELECT pid, authority FROM Projects ORDER BY pid;"
                end
                res = "{\"status\": \"OK\,\n\"data\":["
                tmp.each do |o|
                    o.each do |u|
                        res+=u
                        res+=", "
                    end
                    res.chomp(", ")
                    res+="\n"
                end
                res=res.chomp
                res+="]\n}"
                $result.push(res)
            else
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:votes and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT id, password FROM Member WHERE id=#{i[fname][:member]} AND password=#{i[fname][:password]};"
            if tmp.length > 0
                if i[fname][:action]
                    tmp = $db.exec "SELECT Memberid, up, down FROM (SELECT Memberid, COUNT(updown) AS up FROM Votes WHERE updown=1 GROUP BY Memberid AND Actionaid=#{i[fname][:action]}) AS q1 JOIN (SELECT Memberid, COUNT(updown) AS down FROM Votes WHERE updown=0 AND Actionaid=#{i[fname][:action]} GROUP BY Memberid) AS q2 ON q1.Memberid=q2.Memberid ORDER BY q1.Memberid INCR;"
                elsif i[fname][:project]
                    tmp = $db.exec "SELECT Memberid, up, down FROM (SELECT Memberid, COUNT(updown) AS up FROM (Votes JOIN Action ON Votes.Actionaid=Action.aid) WHERE updown=1 GROUP BY Memberid AND Actionaid=#{i[fname][:action]}) AS q1 JOIN (SELECT Memberid, COUNT(updown) AS down FROM (Votes JOIN Action ON Votes.Actionaid=Action.aid) WHERE updown=0 AND Actionaid=#{i[fname][:project]} GROUP BY Memberid) AS q2 ON q1.Memberid=q2.Memberid ORDER BY q1.Memberid INCR;"
                else
                    tmp = $db.exec "SELECT id AS Memberid, upvotes AS up, downvotes AS down FROM Member;"
                end
                res = "{\"status\": \"OK\,\n\"data\":["
                tmp.each do |o|
                    o.each do |u|
                        res+=u
                        res+=", "
                    end
                    res.chomp(", ")
                    res+="\n"
                end
                res=res.chomp
                res+="]\n}"
                $result.push(res)
            else
                $result.push("{\"status\": \"ERROR\"}")
            end
        elsif fname==:trolls and $allowed_actions.include?(fname)
            tmp = $db.exec "SELECT mid, up, down, last_activity FROM ((SELECT mid, SUM(upvotes) AS up FROM Action WHERE timestamp<#{i[fname][:timestamp]} GROUP BY mid) AS q1 JOIN (SELECT mid, SUM(downvotes) AS down FROM Action WHERE timestamp<#{i[fname][:timestamp]} GROUP BY mid) AS q2 ON q1.mid=q2.mid) JOIN Member ON mid=Member.id;"
            res = "{\"status\": \"OK\,\n\"data\":["
                tmp.each do |o|
                    res+=tmp['mid']
                    res+=", "
                    res+=tmp['up']
                    res+=", "
                    res+=tmp['down']
                    res+=", "
                    
                    if i[fname][:timestamp] - tmp['last_activity'] > $siy
                        res+="\"false\""
                    else
                        res+="\"true\""
                    end

                    res+="\n"
                end
                res=res.chomp
                res+="]\n}"
                $result.push(res)
        end
    end
rescue  PG::Error => exception
    puts {}
ensure
    if db then db.close end
end
#instructions = eval(instructions)


#begin
#    db = PG.connect :dbname => "project_db", :user => "init", :password => "qwerty"
#rescue PG::Error => exception
#    puts exception.message
#ensure
#    if db then db.close end
#end