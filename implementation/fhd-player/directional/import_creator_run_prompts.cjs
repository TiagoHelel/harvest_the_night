// Read the user's real prompt builder without changing its repository.
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
const action = builder.exports.STUDIO_ACTIONS.find(a => a.id === 'run');
const refs = builder.exports.studioReferences(action, 'right', { rotation: true, actionDown: true });
const original = builder.exports.buildDirectionalPrompt(action, 'right', refs);
const style = 'Match the exact approved compact pixel-art farmer: same short proportions, straw hat, blue overalls, brown boots and open white eye. Design for 60 useful native pixels of body height. Simple square pixels, flat readable shading, no blur or antialiasing.';
const adapt = prompt => prompt.replace('Use detailed 32-bit pixel art style with proper shading and highlights.', style);
const keys = adapt(original) + `

These four anchors will occupy frames 0,2,4,6 in an eight-frame run.
Keep the same RIGHT-facing side profile and a modest forward torso lean in all cells. Do not turn toward the viewer. The two legs must exchange roles in the second stride half. The foreground/near leg has brighter brown leather; the far/background leg has darker brown leather. Preserve this ownership in every frame.
TOP LEFT / frame 0: near bright leg extends ahead RIGHT and contacts the shared ground line; far dark leg trails behind LEFT with its heel bent upward.
TOP RIGHT / frame 2: airborne passing: near bright leg curls behind LEFT, far dark knee travels ahead RIGHT; BOTH boots clear the ground. No foot planted.
BOTTOM LEFT / frame 4: opposite contact: far dark leg extends ahead RIGHT and contacts the ground; near bright leg trails behind LEFT with its heel curled upward. This must NOT repeat frame 0.
BOTTOM RIGHT / frame 6: opposite airborne passing: far dark leg curls behind LEFT, near bright knee travels ahead RIGHT; BOTH boots clear the ground. This must NOT repeat frame 2.
Arms are bent at the elbows and pump opposite their corresponding leg; no raised tools. Use the same body size and generous transparent gutters in all cells. Ground registration is identical; airborne sprites remain slightly higher instead of dropping their feet to the ground. Boots must stay brown, not yellow/gold. No shadows, labels, lines or checkerboard.
`;
const intermediates = {
  ...action, label: 'Run transitions',
  frames: [
    'Frame 1: compression/push-off on the near bright leg below the body; dark far heel lifts behind LEFT as its knee starts traveling forward',
    'Frame 3: descending flight: dark far leg extends ahead RIGHT preparing contact, near bright leg trails behind LEFT; both feet clear ground',
    'Frame 5: opposite compression/push-off on the dark far leg below the body; bright near heel lifts behind LEFT as its knee starts traveling forward',
    'Frame 7: opposite descending flight: bright near leg extends ahead RIGHT preparing contact, dark far leg trails behind LEFT; both feet clear ground'
  ],
  notes: 'Only four distinct intermediate poses, not the four anchors. Full playback order is key0, transition1, key2, transition3, key4, transition5, key6, transition7. Lean forward gently, short proportional limbs, bent pumping arms. Near leg is brighter brown, far leg darker brown throughout.'
};
const transitionRefs = builder.exports.studioReferences(action, 'right', { rotation: true, actionDown: false });
const transitions = adapt(builder.exports.buildDirectionalPrompt(intermediates, 'right', transitionRefs)) + `

Additional image 3 contains the four running anchors in reading order (frames 0,2,4,6). Draw the four intermediate poses that connect them. Match exact body scale, face, hat, torso lean, palette and right-facing camera. One support foot at frames 1 and 5; NO ground contact at frames 3 and 7. Both knees and arms exchange their roles between stride halves. Foreground leather is medium brown, background leather dark brown; no yellow boots. Same ground registration in all cells, preserve flight clearance, generous transparent gutters, no labels, shadows, lines or background.
`;
const save = (name, contents) => fs.writeFileSync(path.join(__dirname, 'prompts', name), contents);
save('creator-run-right-base.prompt.txt', original + '\n');
save('creator-run-right-keys.prompt.txt', keys);
save('creator-run-right-transitions.prompt.txt', transitions);
save('creator-run-provenance.json', JSON.stringify({
  repository: repo, file: source,
  source_sha256: crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),
  export: 'buildDirectionalPrompt', action: 'run', direction: 'right', references: refs,
  adaptations: ['Preserve approved compact pixel style', 'Four keys plus four intermediate poses', 'Opposite near/far legs and arms', 'Explicit ground contact versus flight'],
  left_direction: 'Reflect complete right-facing poses and ground pivot'
}, null, 2) + '\n');
console.log('Imported run action and builtDirectionalPrompt; saved base, anchor, transition prompts and provenance.');
