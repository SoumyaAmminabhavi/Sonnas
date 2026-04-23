const https = require('https');
const fs = require('fs');

const images = {
  "classic-chocolate.png": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=800&auto=format&fit=crop",
  "almond-brittle.png": "https://images.unsplash.com/photo-1604085792782-8d92f276d7d8?q=80&w=800&auto=format&fit=crop",
  "orange-chocolate.png": "https://images.unsplash.com/photo-1587314168485-3236d6710814?q=80&w=800&auto=format&fit=crop",
  "hazelnut-chocolate.png": "https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=800&auto=format&fit=crop",
  "coffee-chocolate.png": "https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?q=80&w=800&auto=format&fit=crop",
  "white-chocolate-almond.png": "https://images.unsplash.com/photo-1621236378699-8597faa6a71e?q=80&w=800&auto=format&fit=crop",
  "pina-colada.png": "https://images.unsplash.com/photo-1550617931-e17a7b70dce2?q=80&w=800&auto=format&fit=crop",
  "pineapple.png": "https://images.unsplash.com/photo-1602351447937-745cb720612f?q=80&w=800&auto=format&fit=crop",
  "rich-mawa.png": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?q=80&w=800&auto=format&fit=crop",
  "persian-cake.png": "https://images.unsplash.com/photo-1514338908226-c22f5c7cdcb0?q=80&w=800&auto=format&fit=crop",
  "butter-cake.png": "https://images.unsplash.com/photo-1519869325930-281384150729?q=80&w=800&auto=format&fit=crop",
  "strawberry-vanilla.png": "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?q=80&w=800&auto=format&fit=crop",
  "strawberry-chocolate.png": "https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?q=80&w=800&auto=format&fit=crop"
};

const download = (url, dest) => {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, (response) => {
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
};

async function run() {
  for (const [filename, url] of Object.entries(images)) {
    console.log(`Downloading ${filename}...`);
    try {
      await download(url, `public/images/${filename}`);
    } catch (e) {
      console.error(`Failed: ${filename}`, e);
    }
  }
  console.log("Done");
}

run();
