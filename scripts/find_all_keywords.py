from glob import glob

keywords = set()
audio_files = glob('./new_data/*.wav')
for audio in audio_files:
    audio_name = audio.split('\\')[-1]
    keyword = audio_name.split('-', 1)[0]
    keywords.add(keyword)

print('Found keywords:', keywords)

with open('../flutter_app/keywords.txt', 'w', encoding="utf-8") as f:
    f.write('\n'.join(keywords))
print('Wrote to file:', f)

with open('./keywords.txt', 'w', encoding="utf-8") as f:
    f.write('\n'.join(keywords))
print('Wrote to file:', f)