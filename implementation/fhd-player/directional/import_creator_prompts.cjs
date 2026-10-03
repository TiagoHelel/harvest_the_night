// Read the user's prompt builder without modifying or installing its repository.
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const crypto = require('node:crypto');
const repo = 'C:/Users/Helel/Documents/repos/sprite-sheet-creator';
const source = path.join(repo, 'app/lib/prompts.ts');
const ts = require(path.join(repo, 'node_modules/typescript'));
const compiled = ts.transpileModule(fs.readFileSync(source, 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
}).outputText;
const builder = new Module(source, module);
builder._compile(compiled, source);
const action = builder.exports.STUDIO_ACTIONS.find(a => a.id === 'walk');
const refs = builder.exports.studioReferences(action, 'right', { rotation: true, actionDown: true });
const original = builder.exports.buildDirectionalPrompt(action, 'right', refs);
fs.writeFileSync(path.join(__dirname, 'prompts/creator-walk-right-base.prompt.txt'), original + '\n');
const adapted = original.replace(
  'Use detailed 32-bit pixel art style with proper shading and highlights.',
  'Match the exact approved compact pixel-art farmer references: same short proportions, hat, clothes, open white eye and clean square pixels. Design for 60 useful native pixels of body height. Keep shading simple and edges crisp without blur or antialiasing.'
) + '\n\nDo not redesign the approved farmer. Align the four figures at the same scale and ground baseline with generous fully transparent gutters. The third pose must lead with the OTHER leg, with the two legs exchanging their forward/back positions.\n';
fs.writeFileSync(path.join(__dirname, 'prompts/creator-walk-right-keyposes.prompt.txt'), adapted);
fs.writeFileSync(path.join(__dirname, 'prompts/creator-provenance.json'), JSON.stringify({
  repository: repo, file: source,
  source_sha256: crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),
  export: 'buildDirectionalPrompt', action: 'walk',
  direction: 'right', references: refs,
  adaptations: ['Preserve approved simple pixel art instead of detailed 32-bit styling', 'Fixed scale and ground baseline', 'Explicit opposite-leg contact'],
  expansion: 'Four anchor poses first; four distinct in-between poses then form the requested eight-frame cycle'
}, null, 2) + '\n');
console.log(adapted);
const transitions = {
  ...action,
  label: 'Walk transitions',
  frames: [
    'Between key poses 1 and 2: down/support on the brighter near leg ahead RIGHT; dark far heel lifts behind LEFT, knee bent',
    'Between key poses 2 and 3: brighter near leg supports behind LEFT; dark far leg reaches forward RIGHT just above ground',
    'Between key poses 3 and 4: down/support on the dark far leg ahead RIGHT; brighter near heel lifts behind LEFT, knee bent',
    'Between key poses 4 and 1: dark far leg supports behind LEFT; brighter near leg reaches forward RIGHT just above ground'
  ],
  notes: 'These are ONLY the four in-between poses. The four main poses in attached image 3 remain unchanged. Chronological playback alternates key1, transition1, key2, transition2, key3, transition3, key4, transition4. Keep the foreground leg brighter and background leg darker throughout. Short natural walking strides, no high kicks or running.'
};
const transitionRefs = builder.exports.studioReferences(action, 'right', { rotation: true, actionDown: false });
let transitionPrompt = builder.exports.buildDirectionalPrompt(transitions, 'right', transitionRefs);
transitionPrompt = transitionPrompt.replace(
  'Use detailed 32-bit pixel art style with proper shading and highlights.',
  'Match the exact approved compact pixel-art farmer references, open white eye, short proportions and clean square pixels. Design for 60 useful native pixels body height, simple flat shading, no blur or antialiasing.'
);
transitionPrompt += '\n\nAdditional attached image 3: the four correct RIGHT-facing walking key poses, in 2x2 reading order. Draw the intermediate poses that connect these anchors, with the same head, torso and body scale. Align every figure on the same ground baseline and give it generous transparent gutters. Two connected short legs exchange support; only the indicated leg is lifted.\n';
fs.writeFileSync(path.join(__dirname, 'prompts/creator-walk-right-transitions.prompt.txt'), transitionPrompt);
