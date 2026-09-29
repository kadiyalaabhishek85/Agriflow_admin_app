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

            // Reduce scale from 1.15 to 1.05, and remove the translate if it's cutting off the top
            const imgTarget = 'scale-[1.15] -translate-y-[2px]';
            
            if (content.includes(imgTarget)) {
                content = content.replace(/scale-\[1\.15\] -translate-y-\[2px\]/g, 'scale-[1.05]');
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
