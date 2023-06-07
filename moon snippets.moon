class Player
    new: (@name) =>
      for dir in *{"north", "west", "east", "south"}
        @__base["go_#{dir}"]: =>
          print "#{@name} is going #{dir}"










class GATE
    getWidth: => print 'no @ in first level'
    @getWidth: => print '1  @ in first level'
    
    new: =>
        getWidth: => print 'no @ in second level'
        @getWidth: => print '1  @ in second level'
    
class AND extends GATE
    new: =>
        super!
        super.getWidth!
        super\getWidth!
        @getWidth!
    


print 'GATE'
GATE.getWidth!

gate = GATE!
gate.getWidth!



print 'AND'

AND.getWidth!

print '==>>inside AND constructor'
andgate = AND!
print '<<==outside AND constructor'

andgate.getWidth!