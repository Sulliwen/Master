for file in *.mtx.rnd.json
do
  mv "$file" "${file/.mtx.rnd.json/.json}"
done