// Normalize an approved transparent imagegen foreground; do not reshape its artwork.
// SHARP_MODULE can point to a bundled sharp installation. No runtime dependency is added.
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require(process.env.SHARP_MODULE || 'sharp');
async function main() {
  const source = process.argv[2];
  if (!source) throw new Error('Usage: node tools/prepare-app-icon.cjs <transparent-foreground.png>');
  const metadata = await sharp(source).metadata();
  if (!metadata.hasAlpha || metadata.width !== metadata.height) {
    throw new Error('The approved source must be a square image with transparency.');
  }
  const foreground = await sharp(source).resize(1024, 1024, { kernel: 'lanczos3' }).png().toBuffer();
  const raw = await sharp(foreground).ensureAlpha().raw().toBuffer();
  if (raw[3] !== 0 || raw[(1024 * 1024 - 1) * 4 + 3] !== 0) {
    throw new Error('Foreground corners must be transparent.');
  }
  const background = await sharp({create:{width:1024,height:1024,channels:3,background:'#F6F2E9'}}).png().toBuffer();
  const composed = await sharp(background).composite([{input:foreground}]).png().toBuffer();
  for (const relative of ['AppScope/resources/base/media', 'entry/src/main/resources/base/media']) {
    const dir = path.resolve(__dirname, '..', relative);
    await fs.writeFile(path.join(dir, 'foreground.png'), foreground);
    await fs.writeFile(path.join(dir, 'background.png'), background);
    await fs.writeFile(path.join(dir, 'app_icon.png'), composed);
  }
  await fs.writeFile(path.resolve(__dirname, '../entry/src/main/resources/base/media/start_icon.png'), foreground);
  const exportDir = path.resolve(__dirname, '../assets/app-icon');
  await fs.mkdir(exportDir, {recursive:true});
  await sharp(composed).resize(216,216).png().toFile(path.join(exportDir,'appgallery-icon-216.png'));
  console.log('Prepared 1024px transparent foreground, opaque #F6F2E9 background, composite and 216px export.');
}
main().catch(error => {console.error(error.message);process.exitCode=1;});
