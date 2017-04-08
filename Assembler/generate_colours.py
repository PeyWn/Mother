import sys

file = open("colours2.txt", "w")
for i in range(64):
	for j in range(4):
		for k in range(4):
			for l in range(4):
				a = hex(i * 4 + k)[2:].upper()
				if len(a) == 1:
					a = "0" + a
				file.write("x\"" + a + "\",")
				if k == 3 and l == 3:
					file.write("\n")
				if i%4 == 3 and j == 3 and k == 3 and l == 3:
					file.write("\n\n")

file.close