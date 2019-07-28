# Linguakit Docker image

## Usage

```
./linguakit.sh <module> <lang> <input> [options]
```

or

```
docker run -i brunneis/linguakit <module> <lang> <input> [options]
```

## Example

Command:

```
./linguakit.sh sent es <<< "Hacía bastante que no salía del cine tan feliz. Gracias Christopher Nolan por @Interstellar, merece la pena cada una de las 3h que dura."
```

Output:

```
Hacía bastante que no salía de el cine tan feliz . Gracias Christopher_Nolan por @Interstellar , merece la pena cada una de las 3h que dura . 	POSITIVE	0.999866470435652
TOTAL	POSITIVE	0.999866470435652
```
