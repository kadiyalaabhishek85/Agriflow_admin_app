const fs = require('fs');
const path = require('path');

function replaceInFiles(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            replaceInFiles(fullPath);
        } else if (fullPath.endsWith('.jsx')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            let modified = false;

            // 1. Convert all w-10 h-10 containers to w-14 h-14 rounded-full
            if (content.includes('w-10 h-10 bg-white rounded-xl')) {
                content = content.replace(/w-10 h-10 bg-white rounded-xl/g, 'w-14 h-14 bg-white rounded-full shadow-sm');
                modified = true;
            }

            // 2. Convert all w-9 h-9 containers to w-14 h-14 rounded-full
            if (content.includes('w-9 h-9 rounded-xl')) {
                content = content.replace(/w-9 h-9 rounded-xl/g, 'w-14 h-14 rounded-full');
                modified = true;
            }

            // 3. Update img styling to scale it and object-center
            const imgTarget1 = 'className="w-full h-full object-cover"';
            const imgTarget2 = 'className="w-full h-full object-cover object-center"';
            
            if (content.includes(imgTarget1)) {
                content = content.replace(/className="w-full h-full object-cover"/g, 'className="w-full h-full object-cover object-center scale-[1.15] -translate-y-[2px]"');
                modified = true;
            }
            if (content.includes(imgTarget2)) {
                content = content.replace(/className="w-full h-full object-cover object-center"/g, 'className="w-full h-full object-cover object-center scale-[1.15] -translate-y-[2px]"');
                modified = true;
            }

            if (modified) {
                fs.writeFileSync(fullPath, content);
                console.log('Updated', fullPath);
            }
        }
    }
}

replaceInFiles(path.join(__dirname, 'src'));
console.log('Done!');
