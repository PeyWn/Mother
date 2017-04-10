import sys

mirror_file = open("mirror_tile.txt")
mirror_goal = open("mirror_output.txt",'w')

for line in mirror_file:
    line = line.split(",")
    res = ""
    for pixel in line:
        res = pixel + "," + res
        
    res = res[2:] + "\n"
    res = res.strip(" ")
    mirror_goal.write(res)
