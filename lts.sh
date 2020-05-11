#!/bin/sh -e

ahc-cabal v1-install --ghc-option=-j$jobs --prefix=$ASTERIUS_LIB_DIR --package-db=clear --package-db=global \
  Cabal
ahc-cabal v1-install -j$jobs --prefix=$ASTERIUS_LIB_DIR --package-db=clear --package-db=global \
  AC-Angle \
  ANum \
  Boolean \
  BoundedChan \
  ChannelT \
  ChasingBottoms \
  ClustalParser \
  Color \
  Decimal \
  Diff \
  ENIG \
  Earley \
  FenwickTree \
  FindBin \
  FloatingHex \
  FontyFruity \
  GenericPretty \
  Glob \
  HDBC \
  HDBC-session \
  HSlippyMap \
  HStringTemplate \
  HTTP \
  HUnit \
  HUnit-approx \
  HaXml \
  HandsomeSoup \
  HasBigDecimal \
  HsYAML \
  HsYAML-aeson \
  IPv6Addr \
  IntervalMap \
  List \
  ListLike \
  ListTree \
  MemoTrie \
  MonadPrompt \
  MonadRandom \
  MusicBrainz \
  NineP \
  NoHoed \
  NumInstances \
  ObjectName \
  OneTuple \
  Only \
  ParsecTools \
  QuickCheck \
  RSA \
  Ranged-sets \
  RefSerialize \
  SHA \
  SafeSemaphore \
  StateVar \
  TCache \
  TypeCompose \
  ViennaRNAParser \
  abstract-deque \
  abstract-par \
  ace \
  action-permutations \
  adjunctions \
  adler32 \
  advent-of-code-api \
  aeson \
  aeson-attoparsec \
  aeson-better-errors \
  aeson-casing \
  aeson-compat \
  aeson-default \
  aeson-diff \
  aeson-generic-compat \
  aeson-lens \
  aeson-optics \
  aeson-picker \
  aeson-pretty \
  aeson-schemas \
  aeson-utils \
  aeson-yak \
  aeson-yaml \
  alerts \
  alg \
  algebraic-graphs \
  almost-fix \
  alternative-vector \
  amazonka \
  amazonka-apigateway \
  amazonka-application-autoscaling \
  amazonka-appstream \
  amazonka-athena \
  amazonka-autoscaling \
  amazonka-budgets \
  amazonka-certificatemanager \
  amazonka-cloudformation \
  amazonka-cloudfront \
  amazonka-cloudhsm \
  amazonka-cloudsearch \
  amazonka-cloudsearch-domains \
  amazonka-cloudtrail \
  amazonka-cloudwatch \
  amazonka-cloudwatch-events \
  amazonka-cloudwatch-logs \
  amazonka-codebuild \
  amazonka-codecommit \
  amazonka-codedeploy \
  amazonka-codepipeline \
  amazonka-cognito-identity \
  amazonka-cognito-idp \
  amazonka-cognito-sync \
  amazonka-config \
  amazonka-core \
  amazonka-datapipeline \
  amazonka-devicefarm \
  amazonka-directconnect \
  amazonka-discovery \
  amazonka-dms \
  amazonka-ds \
  amazonka-dynamodb \
  amazonka-dynamodb-streams \
  amazonka-ecr \
  amazonka-ecs \
  amazonka-efs \
  amazonka-elasticache \
  amazonka-elasticbeanstalk \
  amazonka-elasticsearch \
  amazonka-elastictranscoder \
  amazonka-elb \
  amazonka-elbv2 \
  amazonka-emr \
  amazonka-gamelift \
  amazonka-glacier \
  amazonka-glue \
  amazonka-health \
  amazonka-iam \
  amazonka-importexport \
  amazonka-inspector \
  amazonka-iot \
  amazonka-iot-dataplane \
  amazonka-kinesis \
  amazonka-kinesis-analytics \
  amazonka-kinesis-firehose \
  amazonka-kms \
  amazonka-lambda \
  amazonka-lightsail \
  amazonka-marketplace-analytics \
  amazonka-marketplace-metering \
  amazonka-ml \
  amazonka-opsworks \
  amazonka-opsworks-cm \
  amazonka-pinpoint \
  amazonka-polly \
  amazonka-rds \
  amazonka-redshift \
  amazonka-rekognition \
  amazonka-route53 \
  amazonka-route53-domains \
  amazonka-s3 \
  amazonka-sdb \
  amazonka-servicecatalog \
  amazonka-ses \
  amazonka-shield \
  amazonka-sms \
  amazonka-snowball \
  amazonka-sns \
  amazonka-sqs \
  amazonka-ssm \
  amazonka-stepfunctions \
  amazonka-storagegateway \
  amazonka-sts \
  amazonka-support \
  amazonka-swf \
  amazonka-waf \
  amazonka-workspaces \
  amazonka-xray \
  amqp \
  annotated-wl-pprint \
  ansi-terminal \
  ansi-wl-pprint \
  antiope-core \
  antiope-dynamodb \
  antiope-messages \
  antiope-s3 \
  antiope-sns \
  antiope-sqs \
  api-field-json-th \
  app-settings \
  appar \
  appendmap \
  apportionment \
  arbor-lru-cache \
  array-memoize \
  arrow-extras \
  ascii-progress \
  asn1-encoding \
  asn1-parse \
  asn1-types \
  assert-failure \
  assoc \
  astro \
  async \
  async-extra \
  async-timer \
  atom-basic \
  atomic-primops \
  atomic-write \
  attoparsec \
  attoparsec-base64 \
  attoparsec-binary \
  attoparsec-expr \
  attoparsec-ip \
  attoparsec-iso8601 \
  attoparsec-path \
  attoparsec-uri \
  audacity \
  aur \
  authenticate \
  authenticate-oauth \
  auto \
  auto-update \
  autoexporter \
  avro \
  aws-cloudfront-signed-cookies \
  base-compat \
  base-compat-batteries \
  base-orphans \
  base-prelude \
  base-unicode-symbols \
  base16-bytestring \
  base32string \
  base58string \
  base64 \
  base64-bytestring \
  base64-bytestring-type \
  base64-lens \
  base64-string \
  basement \
  basic-prelude \
  bazel-runfiles \
  bbdb \
  bcrypt \
  bech32 \
  between \
  bibtex \
  bifunctors \
  bimap \
  bimap-server \
  bimaps \
  bin \
  binary-conduit \
  binary-ext \
  binary-ieee754 \
  binary-list \
  binary-orphans \
  binary-parser \
  binary-parsers \
  binary-search \
  binary-shared \
  bindings-DSL \
  bindings-uname \
  bitarray \
  bits-extra \
  bitvec \
  blake2 \
  blanks \
  blaze-bootstrap \
  blaze-builder \
  blaze-html \
  blaze-markup \
  blaze-svg \
  blaze-textual \
  bmp \
  boolean-like \
  boolean-normal-forms \
  boolsimplifier \
  boots \
  bordacount \
  both \
  bound \
  bounded-queue \
  boundingboxes \
  bower-json \
  boxes \
  bsb-http-chunked \
  bson \
  btrfs \
  buffer-builder \
  bugsnag-hs \
  bv \
  byte-order \
  byteable \
  bytebuild \
  bytedump \
  byteorder \
  bytes \
  byteset \
  byteslice \
  bytesmith \
  bytestring-builder \
  bytestring-lexing \
  bytestring-strict-builder \
  bytestring-to-vector \
  bytestring-tree-builder \
  bz2 \
  ca-province-codes \
  cabal-doctest \
  cabal-plan \
  cabal2spec \
  cache \
  call-stack \
  can-i-haz \
  carray \
  casa-client \
  casa-types \
  case-insensitive \
  cased \
  casing \
  cassava \
  cassava-conduit \
  cassava-megaparsec \
  cast \
  category \
  cayley-client \
  cborg \
  cborg-json \
  cereal \
  cereal-conduit \
  cereal-text \
  cereal-vector \
  cfenv \
  chan \
  charset \
  chaselev-deque \
  checkers \
  checksum \
  chimera \
  choice \
  chronologique \
  chronos \
  chronos-bench \
  chunked-data \
  cipher-aes \
  cipher-camellia \
  cipher-des \
  cipher-rc4 \
  circle-packing \
  classy-prelude \
  classy-prelude-conduit \
  clay \
  clientsession \
  climb \
  clock \
  clock-extras \
  clr-marshal \
  clumpiness \
  cmark \
  cmark-gfm \
  cmark-lucid \
  cmdargs \
  co-log-core \
  code-page \
  codec-beam \
  coercible-utils \
  colorful-monoids \
  colorize-haskell \
  colour \
  colourista \
  combinatorial \
  comfort-array \
  comfort-graph \
  commutative \
  comonad \
  compactmap \
  compiler-warnings \
  composable-associations \
  composable-associations-aeson \
  composition \
  composition-extra \
  concise \
  concurrency \
  concurrent-extra \
  concurrent-output \
  concurrent-split \
  cond \
  conduit \
  conduit-combinators \
  conduit-concurrent-map \
  conduit-extra \
  conduit-zstd \
  conferer \
  conferer-hspec \
  conferer-provider-json \
  conferer-warp \
  config-ini \
  configurator \
  configurator-export \
  connection \
  connection-pool \
  console-style \
  constraint \
  constraint-tuples \
  constraints \
  contiguous \
  contravariant \
  control-bool \
  control-monad-free \
  control-monad-omega \
  convertible \
  cookie \
  core-data \
  core-text \
  countable \
  cpio-conduit \
  cpphs \
  cprng-aes \
  cpu \
  cpuinfo \
  crackNum \
  criterion-measurement \
  cron \
  crypt-sha512 \
  crypto-api \
  crypto-cipher-types \
  crypto-enigma \
  crypto-numbers \
  crypto-pubkey \
  crypto-pubkey-types \
  crypto-random \
  crypto-random-api \
  cryptohash \
  cryptohash-cryptoapi \
  cryptohash-md5 \
  cryptohash-sha1 \
  cryptohash-sha256 \
  cryptohash-sha512 \
  cryptonite \
  cryptonite-conduit \
  csp \
  css-text \
  csv \
  csv-conduit \
  ctrie \
  cue-sheet \
  currencies \
  currency \
  cursor \
  cursor-fuzzy-time \
  czipwith \
  data-accessor \
  data-accessor-mtl \
  data-accessor-transformers \
  data-binary-ieee754 \
  data-bword \
  data-checked \
  data-clist \
  data-default \
  data-default-class \
  data-default-instances-containers \
  data-default-instances-dlist \
  data-default-instances-old-locale \
  data-diverse \
  data-endian \
  data-fix \
  data-has \
  data-interval \
  data-inttrie \
  data-lens-light \
  data-memocombinators \
  data-or \
  data-ordlist \
  data-ref \
  data-reify \
  data-tree-print \
  dataurl \
  debian-build \
  debug-trace-var \
  dec \
  deepseq-generics \
  dejafu \
  deque \
  deriveJsonNoPrefix \
  deriving-compat \
  derulo \
  detour-via-sci \
  di-core \
  di-monad \
  diagrams-solve \
  dictionary-sharing \
  digest \
  digits \
  dimensional \
  directory-tree \
  disk-free-space \
  distributive \
  dlist \
  dlist-instances \
  dlist-nonempty \
  dns \
  do-list \
  do-notation \
  dockerfile \
  doclayout \
  doctemplates \
  doctest-driver-gen \
  doldol \
  dotenv \
  dotgen \
  dotnet-timespan \
  drinkery \
  dsp \
  dual \
  dual-tree \
  dublincore-xml-conduit \
  dunai \
  duration \
  dvorak \
  dynamic-state \
  dyre \
  eap \
  easy-file \
  echo \
  ecstasy \
  ed25519 \
  edit-distance \
  edit-distance-vector \
  editor-open \
  either \
  either-both \
  either-unwrap \
  elerea \
  elf \
  elm-bridge \
  email-validate \
  emojis \
  enclosed-exceptions \
  entropy \
  enum-subset-generate \
  enummapset \
  enumset \
  envelope \
  envy \
  epub-metadata \
  eq \
  erf \
  errors \
  errors-ext \
  esqueleto \
  etc \
  event-list \
  eventful-core \
  every \
  exact-combinatorics \
  exact-pi \
  exception-hierarchy \
  exception-mtl \
  exception-transformers \
  exceptions \
  executable-path \
  exit-codes \
  exomizer \
  exp-pairs \
  expiring-cache-map \
  explicit-exception \
  express \
  extended-reals \
  extensible-effects \
  extensible-exceptions \
  extra \
  extractable-singleton \
  extrapolate \
  fail \
  failable \
  fast-logger \
  fast-math \
  fb \
  feature-flags \
  fedora-dists \
  feed \
  file-embed \
  filecache \
  filelock \
  filemanip \
  filepattern \
  fileplow \
  filtrable \
  fin \
  fingertree \
  finite-typelits \
  first-class-families \
  first-class-patterns \
  fitspec \
  fixed \
  fixed-length \
  fixed-vector \
  fixed-vector-hetero \
  flags-applicative \
  floatshow \
  flow \
  flush-queue \
  fmlist \
  fn \
  focus \
  fold-debounce \
  fold-debounce-conduit \
  foldable1 \
  folds \
  follow-file \
  foreign-store \
  forkable-monad \
  forma \
  format-numbers \
  foundation \
  free \
  free-categories \
  free-vl \
  freer-simple \
  freetype2 \
  friendly-time \
  from-sum \
  frontmatter \
  fsnotify \
  fsnotify-conduit \
  funcmp \
  function-builder \
  functor-classes-compat \
  fused-effects \
  fusion-plugin-types \
  fuzzcheck \
  fuzzy \
  fuzzy-time \
  fuzzyset \
  gauge \
  gdp \
  general-games \
  generic-arbitrary \
  generic-constraints \
  generic-data \
  generic-deriving \
  generic-lens \
  generic-monoid \
  generic-random \
  ghc-compact \
  ghc-lib \
  ghc-lib-parser \
  ghc-paths \
  ghc-prof \
  ghc-syntax-highlighter \
  ghci-hexcalc \
  ghcid \
  ghcjs-codemirror \
  ghost-buster \
  githash \
  github-rest \
  github-types \
  gitlab-haskell \
  gitrev \
  glabrous \
  gnuplot \
  google-isbn \
  gothic \
  gpolyline \
  graph-core \
  graph-wrapper \
  graphs \
  gravatar \
  greskell \
  greskell-core \
  greskell-websocket \
  groom \
  groups \
  guarded-allocation \
  hackage-db \
  hackage-security \
  haddock-library \
  half \
  hashable \
  hashable-time \
  hashids \
  hashmap \
  hashtables \
  haskeline \
  haskell-gi-overloading \
  haskell-lexer \
  haskell-src \
  haskell-src-exts \
  haskey-btree \
  hdaemonize \
  heap \
  heaps \
  hebrew-time \
  hedgehog \
  hedgehog-corpus \
  hedgehog-fn \
  hedgehog-quickcheck \
  hedis \
  heredoc \
  hexml \
  hexml-lens \
  hexstring \
  hformat \
  hi-file-parser \
  highlighting-kate \
  hinfo \
  hinotify \
  hjsmin \
  hlibcpuid \
  hnock \
  hoauth2 \
  hopfli \
  hosc \
  hostname \
  hostname-validate \
  hourglass \
  hpack \
  hpc-codecov \
  hreader \
  hreader-lens \
  hs-bibutils \
  hs-functors \
  hs-php-session \
  hscolour \
  hsebaysdk \
  hset \
  hsini \
  hslogger \
  hslua \
  hslua-aeson \
  hslua-module-system \
  hslua-module-text \
  hsp \
  hspec \
  hspec-attoparsec \
  hspec-checkers \
  hspec-contrib \
  hspec-core \
  hspec-discover \
  hspec-expectations \
  hspec-expectations-lifted \
  hspec-expectations-pretty-diff \
  hspec-golden \
  hspec-golden-aeson \
  hspec-leancheck \
  hspec-megaparsec \
  hspec-meta \
  hspec-need-env \
  hspec-parsec \
  hspec-smallcheck \
  hspec-wai \
  hsshellscript \
  hsyslog \
  html \
  html-conduit \
  html-entities \
  html-entity-map \
  htoml \
  http-api-data \
  http-client \
  http-client-overrides \
  http-client-tls \
  http-common \
  http-conduit \
  http-date \
  http-directory \
  http-media \
  http-reverse-proxy \
  http-types \
  http2 \
  httpd-shed \
  human-readable-duration \
  hunit-dejafu \
  hvect \
  hvega \
  hw-conduit \
  hw-conduit-merges \
  hw-diagnostics \
  hw-hedgehog \
  hw-hspec-hedgehog \
  hw-int \
  hw-mquery \
  hw-string-parse \
  hweblib \
  hxt \
  hxt-charproperties \
  hxt-css \
  hxt-http \
  hxt-regex-xmlschema \
  hxt-tagsoup \
  hxt-unicode \
  hybrid-vectors \
  hyphenation \
  iconv \
  ieee754 \
  if \
  iff \
  ilist \
  imagesize-conduit \
  immortal \
  include-file \
  indents \
  indexed \
  indexed-list-literals \
  indexed-profunctors \
  infer-license \
  inflections \
  ini \
  inj \
  insert-ordered-containers \
  instance-control \
  int-cast \
  integer-logarithms \
  integration \
  intern \
  interpolation \
  intervals \
  intro \
  intset-imperative \
  invariant \
  io-machine \
  io-manager \
  io-memoize \
  io-region \
  io-storage \
  io-streams \
  io-streams-haproxy \
  ip \
  iproute \
  ipynb \
  irc \
  irc-conduit \
  irc-ctcp \
  islink \
  iso3166-country-codes \
  iso639 \
  iso8601-time \
  iterable \
  ix-shapable \
  jira-wiki-markup \
  jose-jwt \
  js-dgtable \
  js-flot \
  js-jquery \
  json-alt \
  json-feed \
  json-rpc-generic \
  jsonpath \
  junit-xml \
  justified-containers \
  jwt \
  kan-extensions \
  kanji \
  kawhi \
  kazura-queue \
  kdt \
  keycode \
  keys \
  kind-apply \
  kind-generics \
  kind-generics-th \
  kmeans \
  kubernetes-webhook-haskell \
  l10n \
  language-avro \
  language-c \
  language-haskell-extract \
  language-java \
  language-javascript \
  language-protobuf \
  largeword \
  latex \
  lattices \
  lawful \
  lazy-csv \
  lazyio \
  lca \
  leancheck \
  leancheck-instances \
  leapseconds-announced \
  lens \
  lens-action \
  lens-aeson \
  lens-datetime \
  lens-family \
  lens-family-core \
  lens-family-th \
  lens-misc \
  lens-properties \
  lenz \
  libgit \
  libgraph \
  libmpd \
  libyaml \
  lift-generics \
  lifted-async \
  lifted-base \
  linenoise \
  linux-file-extents \
  linux-namespaces \
  list-singleton \
  listsafe \
  llvm-hs-pure \
  load-env \
  loch-th \
  lockfree-queue \
  log-base \
  logfloat \
  logging-effect \
  logging-facade \
  logging-facade-syslog \
  logict \
  loop \
  lrucache \
  lrucaching \
  lucid \
  lucid-extras \
  lukko \
  machines \
  main-tester \
  mainland-pretty \
  makefile \
  managed \
  markdown \
  markdown-unlit \
  markov-chain \
  massiv \
  massiv-test \
  mathexpr \
  matplotlib \
  matrices \
  matrix \
  matrix-market-attoparsec \
  maximal-cliques \
  mbox \
  median-stream \
  megaparsec \
  megaparsec-tests \
  membrain \
  memory \
  mercury-api \
  mergeful \
  mersenne-random-pure64 \
  messagepack \
  mfsolve \
  microlens \
  microlens-aeson \
  microlens-contra \
  microlens-ghc \
  microlens-mtl \
  microlens-platform \
  microlens-process \
  microlens-th \
  microspec \
  microstache \
  midair \
  midi \
  mime-mail \
  mime-mail-ses \
  mime-types \
  minimal-configuration \
  minimorph \
  minio-hs \
  miniutter \
  mintty \
  miso \
  missing-foreign \
  mixpanel-client \
  mmap \
  mmorph \
  mnist-idx \
  mockery \
  modern-uri \
  monad-control \
  monad-control-aligned \
  monad-coroutine \
  monad-extras \
  monad-journal \
  monad-logger \
  monad-logger-json \
  monad-logger-prefix \
  monad-loops \
  monad-memo \
  monad-par-extras \
  monad-parallel \
  monad-peel \
  monad-products \
  monad-resumption \
  monad-skeleton \
  monad-st \
  monad-time \
  monad-unlift \
  monad-unlift-ref \
  monadic-arrays \
  monads-tf \
  mongoDB \
  mono-traversable \
  mono-traversable-instances \
  mono-traversable-keys \
  monoid-extras \
  monoid-subclasses \
  monoid-transformer \
  more-containers \
  mountpoints \
  mtl-compat \
  mtl-prelude \
  multiarg \
  multimap \
  multiset \
  multistate \
  murmur-hash \
  murmur3 \
  mutable-containers \
  mx-state-codes \
  n2o \
  nagios-check \
  names-th \
  nano-erl \
  nanospec \
  nats \
  natural-arithmetic \
  natural-induction \
  natural-sort \
  natural-transformation \
  ndjson-conduit \
  neat-interpolation \
  netlib-carray \
  netlib-comfort-array \
  netlib-ffi \
  netrc \
  netwire \
  netwire-input \
  network \
  network-bsd \
  network-byte-order \
  network-conduit-tls \
  network-info \
  network-simple \
  network-simple-tls \
  network-transport \
  network-transport-composed \
  network-uri \
  newtype \
  newtype-generics \
  nicify-lib \
  no-value \
  non-empty \
  non-empty-sequence \
  non-negative \
  nonce \
  nondeterminism \
  nonempty-containers \
  nonempty-vector \
  nonemptymap \
  nowdoc \
  nqe \
  numbers \
  numeric-prelude \
  numhask \
  numtype-dk \
  nuxeo \
  o-clock \
  oauthenticated \
  oeis2 \
  ofx \
  old-locale \
  old-time \
  one-liner \
  one-liner-instances \
  oo-prototypes \
  open-browser \
  openexr-write \
  openpgp-asciiarmor \
  opentelemetry \
  operational \
  operational-class \
  optics \
  optics-core \
  optics-extra \
  optics-th \
  optics-vl \
  optional-args \
  options \
  optparse-applicative \
  optparse-generic \
  optparse-simple \
  optparse-text \
  ordered-containers \
  overhang \
  packcheck \
  pager \
  pagination \
  pandoc-types \
  papillon \
  parallel \
  parallel-io \
  paripari \
  parseargs \
  parsec-class \
  parsec-numbers \
  parsec-numeric \
  parser-combinators \
  partial-handler \
  password \
  password-instances \
  path \
  path-pieces \
  pathtype \
  pathwalk \
  pattern-arrows \
  pcg-random \
  pcre-utils \
  pdfinfo \
  peano \
  pem \
  percent-format \
  perfect-hash-generator \
  perfect-vector-shuffle \
  persist \
  persistent \
  persistent-template \
  persistent-typed-db \
  pg-harness-client \
  pgp-wordlist \
  phantom-state \
  pid1 \
  pipes \
  pipes-aeson \
  pipes-attoparsec \
  pipes-binary \
  pipes-bytestring \
  pipes-concurrency \
  pipes-csv \
  pipes-fastx \
  pipes-group \
  pipes-http \
  pipes-network \
  pipes-network-tls \
  pipes-ordered-zip \
  pipes-parse \
  pipes-safe \
  pipes-wai \
  pkcs10 \
  placeholders \
  pointed \
  pointedlist \
  pointless-fun \
  poll \
  poly-arity \
  polynomials-bernstein \
  polyparse \
  pooled-io \
  port-utils \
  posix-paths \
  possibly \
  post-mess-age \
  postgres-options \
  pptable \
  pqueue \
  prefix-units \
  prelude-compat \
  prelude-safeenum \
  pretty-class \
  pretty-hex \
  pretty-relative-time \
  pretty-show \
  pretty-simple \
  pretty-types \
  prettyclass \
  prettyprinter \
  prettyprinter-ansi-terminal \
  prettyprinter-compat-annotated-wl-pprint \
  prettyprinter-compat-ansi-wl-pprint \
  prettyprinter-compat-wl-pprint \
  prettyprinter-convert-ansi-wl-pprint \
  primes \
  primitive \
  primitive-addr \
  primitive-offset \
  primitive-unaligned \
  primitive-unlifted \
  print-console-colors \
  process-extras \
  profunctors \
  project-template \
  projectroot \
  prometheus-client \
  promises \
  prompt \
  prospect \
  proto-lens \
  proto-lens-arbitrary \
  proto-lens-optparse \
  proto-lens-runtime \
  protobuf-simple \
  protolude \
  proxied \
  psqueues \
  pureMD5 \
  pusher-http-haskell \
  qrcode-core \
  quickcheck-arbitrary-adt \
  quickcheck-assertions \
  quickcheck-classes-base \
  quickcheck-instances \
  quickcheck-io \
  quickcheck-simple \
  quickcheck-special \
  quickcheck-text \
  quickcheck-transformer \
  quickcheck-unicode \
  radius \
  ral \
  ramus \
  rando \
  random \
  random-shuffle \
  random-tree \
  range \
  range-set-list \
  rank1dynamic \
  rank2classes \
  ratel \
  ratel-wai \
  raw-strings-qq \
  rawfilepath \
  rawstring-qm \
  rcu \
  rdtsc \
  read-editor \
  read-env-var \
  readable \
  record-hasfield \
  recursion-schemes \
  reducers \
  ref-fd \
  refact \
  reflection \
  regex \
  regex-applicative \
  regex-applicative-text \
  regex-base \
  regex-compat \
  regex-compat-tdfa \
  regex-pcre-builtin \
  regex-posix \
  regex-tdfa \
  regex-with-pcre \
  registry \
  reinterpret-cast \
  relapse \
  relude \
  renderable \
  replace-attoparsec \
  replace-megaparsec \
  repline \
  resolv \
  resource-pool \
  resourcet \
  result \
  rethinkdb-client-driver \
  retry \
  rev-state \
  rfc1751 \
  rfc5051 \
  rigel-viz \
  rio \
  rio-orphans \
  rio-prettyprint \
  roc-id \
  roles \
  rope-utf16-splay \
  rosezipper \
  rot13 \
  run-st \
  runmemo \
  safe \
  safe-decimal \
  safe-exceptions \
  safe-exceptions-checked \
  safe-foldable \
  safe-json \
  safe-money \
  safecopy \
  safeio \
  salak \
  salak-yaml \
  salve \
  sample-frame \
  sample-frame-np \
  say \
  scalpel \
  scalpel-core \
  scanf \
  scanner \
  scheduler \
  scientific \
  scotty \
  scrypt \
  search-algorithms \
  securemem \
  selda \
  selda-json \
  selective \
  semialign \
  semialign-indexed \
  semialign-optics \
  semigroupoid-extras \
  semigroupoids \
  semigroups \
  semiring-simple \
  semver \
  sendfile \
  seqalign \
  serf \
  serialise \
  servant \
  servant-auth \
  servant-blaze \
  servant-cassava \
  servant-client \
  servant-client-core \
  servant-conduit \
  servant-lucid \
  servant-machines \
  servant-pipes \
  servant-yaml \
  serversession \
  serversession-frontend-wai \
  set-cover \
  setenv \
  setlocale \
  shared-memory \
  shell-escape \
  shell-utility \
  shelly \
  should-not-typecheck \
  show-combinators \
  siggy-chardust \
  signal \
  silently \
  simple-affine-space \
  simple-cabal \
  simple-cmd \
  simple-cmd-args \
  simple-reflect \
  simple-sendfile \
  simple-templates \
  simple-vec3 \
  simplistic-generics \
  since \
  singleton-bool \
  siphash \
  sitemap-gen \
  size-based \
  skein \
  skip-var \
  skylighting \
  skylighting-core \
  slist \
  small-bytearray-builder \
  smallcheck \
  snap-blaze \
  snap-core \
  snap-server \
  snowflake \
  soap \
  soap-tls \
  socks \
  some \
  sop-core \
  sort \
  sorted-list \
  sourcemap \
  sox \
  sparse-linear-algebra \
  special-values \
  speculate \
  splice \
  split \
  splitmix \
  spoon \
  spreadsheet \
  sql-words \
  srcloc \
  stache \
  starter \
  stateref \
  statestack \
  step-function \
  stm-chans \
  stm-conduit \
  stm-delay \
  stm-extras \
  stm-split \
  stopwatch \
  storable-complex \
  storable-record \
  storable-tuple \
  storablevector \
  streaming \
  streaming-commons \
  streams \
  strict \
  strict-base-types \
  strict-concurrency \
  strict-list \
  string-class \
  string-combinators \
  string-conv \
  string-conversions \
  string-qq \
  string-transform \
  stringbuilder \
  stringsearch \
  stripe-concepts \
  stripe-signature \
  structured-cli \
  sum-type-boilerplate \
  sundown \
  superbuffer \
  svg-builder \
  swagger \
  syb \
  symbol \
  symengine \
  sysinfo \
  system-argv0 \
  system-fileio \
  system-filepath \
  system-info \
  systemd \
  tabular \
  tagchup \
  tagged \
  tagged-binary \
  tagged-identity \
  tagged-transformer \
  tagshare \
  tagsoup \
  tao \
  tao-example \
  tar \
  tar-conduit \
  tardis \
  tasty \
  tasty-ant-xml \
  tasty-dejafu \
  tasty-discover \
  tasty-expected-failure \
  tasty-golden \
  tasty-hedgehog \
  tasty-hspec \
  tasty-hunit \
  tasty-kat \
  tasty-leancheck \
  tasty-program \
  tasty-quickcheck \
  tasty-rerun \
  tasty-silver \
  tasty-smallcheck \
  tasty-th \
  tasty-wai \
  tce-conf \
  tdigest \
  template-haskell-compat-v0208 \
  temporary \
  temporary-rc \
  temporary-resourcet \
  tensorflow-test \
  tensors \
  terminal-progress-bar \
  terminal-size \
  test-framework \
  test-framework-hunit \
  test-framework-leancheck \
  test-framework-quickcheck2 \
  test-framework-smallcheck \
  test-framework-th \
  testing-feat \
  testing-type-modifiers \
  texmath \
  text-binary \
  text-conversions \
  text-latin1 \
  text-ldap \
  text-manipulate \
  text-metrics \
  text-postgresql \
  text-printer \
  text-short \
  text-zipper \
  textlocal \
  tf-random \
  tfp \
  th-abstraction \
  th-data-compat \
  th-expand-syns \
  th-extras \
  th-lift \
  th-lift-instances \
  th-reify-compat \
  th-reify-many \
  th-strict-compat \
  th-test-utils \
  these \
  these-lens \
  these-optics \
  thread-hierarchy \
  thread-local-storage \
  thread-supervisor \
  threads \
  throttle-io-stream \
  tile \
  time-compat \
  time-lens \
  time-locale-compat \
  time-locale-vietnamese \
  time-manager \
  timeit \
  timelens \
  timerep \
  timezone-olson \
  timezone-series \
  titlecase \
  tldr \
  tls \
  tls-session-manager \
  tmapchan \
  tmapmvar \
  tonalude \
  topograph \
  torsor \
  tostring \
  tracing \
  transaction \
  transformers-base \
  transformers-bifunctors \
  transformers-compat \
  transformers-fix \
  tree-fun \
  triplesec \
  trivial-constraint \
  tsv2csv \
  ttl-hashtables \
  ttrie \
  tuple \
  tuple-th \
  tuples-homogenous-h98 \
  type-equality \
  type-errors \
  type-errors-pretty \
  type-fun \
  type-hint \
  type-level-integers \
  type-level-kv-list \
  type-map \
  type-operators \
  type-spec \
  typed-process \
  typed-uuid \
  typenums \
  typerep-map \
  uglymemo \
  unagi-chan \
  unbounded-delays \
  unboxed-ref \
  unboxing-vector \
  unconstrained \
  unicode \
  unicode-show \
  unicode-transforms \
  unification-fd \
  union-find \
  uniprot-kb \
  unique \
  unique-logic \
  unique-logic-tf \
  unit-constraint \
  universe \
  universe-base \
  universe-instances-base \
  universe-instances-extended \
  universe-instances-trans \
  universe-reverse-instances \
  universe-some \
  universum \
  unix-bytestring \
  unix-compat \
  unix-time \
  unliftio \
  unliftio-core \
  unliftio-pool \
  unlit \
  unordered-containers \
  unordered-intmap \
  unsafe \
  urbit-hob \
  uri-bytestring \
  uri-bytestring-aeson \
  uri-encode \
  url \
  users \
  utf8-light \
  utf8-string \
  util \
  utility-ht \
  uuid \
  uuid-types \
  validation \
  validity \
  validity-aeson \
  validity-bytestring \
  validity-containers \
  validity-path \
  validity-primitive \
  validity-scientific \
  validity-text \
  validity-time \
  validity-unordered-containers \
  validity-uuid \
  validity-vector \
  valor \
  vault \
  vec \
  vector \
  vector-algorithms \
  vector-binary-instances \
  vector-buffer \
  vector-builder \
  vector-bytes-instances \
  vector-instances \
  vector-mmap \
  vector-rotcev \
  vector-sized \
  vector-space \
  vector-split \
  vector-th-unbox \
  versions \
  vformat \
  vformat-aeson \
  vformat-time \
  void \
  wai \
  wai-conduit \
  wai-cors \
  wai-enforce-https \
  wai-eventsource \
  wai-extra \
  wai-handler-launch \
  wai-logger \
  wai-middleware-caching \
  wai-middleware-static \
  wai-session \
  wai-slack-middleware \
  warp \
  warp-tls \
  warp-tls-uid \
  wave \
  wcwidth \
  webrtc-vad \
  websockets \
  websockets-snap \
  weeder \
  wide-word \
  wikicfp-scraper \
  wild-bind \
  with-location \
  witness \
  wizards \
  wl-pprint-annotated \
  wl-pprint-console \
  wl-pprint-text \
  word-trie \
  word-wrap \
  word24 \
  word8 \
  world-peace \
  wrap \
  writer-cps-exceptions \
  writer-cps-mtl \
  writer-cps-transformers \
  wuss \
  x509 \
  x509-store \
  x509-system \
  x509-validation \
  xdg-basedir \
  xdg-userdirs \
  xeno \
  xml \
  xml-basic \
  xml-conduit \
  xml-conduit-writer \
  xml-indexed-cursor \
  xml-lens \
  xml-picklers \
  xml-to-json-fast \
  xml-types \
  xmlgen \
  xss-sanitize \
  xxhash-ffi \
  yaml \
  yes-precure5-command \
  yi-rope \
  yjsvg \
  yjtools \
  zero \
  zip-archive \
  zip-stream \
  zlib \
  zlib-bindings \
  zlib-lens \
  zstd
ahc-cabal v1-install -j$jobs_th --prefix=$ASTERIUS_LIB_DIR --package-db=clear --package-db=global \
  Chart \
  Chart-diagrams \
  DAV \
  ForestStructures \
  HTF \
  JuicyPixels \
  JuicyPixels-extra \
  PyF \
  QuasiText \
  Rasterific \
  SVGFonts \
  Spintax \
  Taxonomy \
  accuerr \
  active \
  ad \
  aeson-qq \
  amazonka-test \
  apecs \
  approximate \
  asciidiagram \
  asif \
  avers \
  binary-tagged \
  bits \
  bitset-word8 \
  boring \
  brick \
  butcher \
  cacophony \
  cases \
  classy-prelude-yesod \
  compensated \
  conduit-parse \
  contravariant-extras \
  core-program \
  criterion \
  cubicbezier \
  cuckoo-filter \
  cursor-brick \
  cursor-gen \
  data-dword \
  data-serializer \
  data-textual \
  datadog \
  declarative \
  deferred-folds \
  dense-linear-algebra \
  dhall \
  dhall-json \
  dhall-yaml \
  diagrams \
  diagrams-contrib \
  diagrams-core \
  diagrams-lib \
  diagrams-postscript \
  diagrams-rasterific \
  diagrams-svg \
  distributed-closure \
  distribution-nixpkgs \
  distribution-opensuse \
  eliminators \
  elm-core-sources \
  elm2nix \
  emacs-module \
  equational-reasoning \
  ersatz \
  eventful-test-helpers \
  fgl \
  focuslist \
  foldl \
  force-layout \
  fuzzy-dates \
  generics-sop \
  generics-sop-lens \
  genvalidity \
  genvalidity-aeson \
  genvalidity-bytestring \
  genvalidity-containers \
  genvalidity-criterion \
  genvalidity-hspec \
  genvalidity-hspec-aeson \
  genvalidity-hspec-binary \
  genvalidity-hspec-cereal \
  genvalidity-hspec-hashable \
  genvalidity-hspec-optics \
  genvalidity-hspec-persistent \
  genvalidity-mergeful \
  genvalidity-mergeless \
  genvalidity-path \
  genvalidity-property \
  genvalidity-scientific \
  genvalidity-text \
  genvalidity-time \
  genvalidity-typed-uuid \
  genvalidity-unordered-containers \
  genvalidity-uuid \
  genvalidity-vector \
  geojson \
  getopt-generics \
  giphy-api \
  graphite \
  graphviz \
  haskell-lsp \
  haskell-lsp-types \
  haskell-names \
  haskell-src-exts-util \
  haskell-src-meta \
  hasty-hamiltonian \
  heart-core \
  here \
  heterocephalus \
  hledger-iadd \
  hledger-lib \
  hourglass-orphans \
  hsemail \
  hsinstall \
  http-download \
  hw-balancedparens \
  hw-bits \
  hw-dsv \
  hw-eliasfano \
  hw-excess \
  hw-fingertree \
  hw-fingertree-strict \
  hw-ip \
  hw-json \
  hw-json-simd \
  hw-json-simple-cursor \
  hw-json-standard-cursor \
  hw-packed-vector \
  hw-parser \
  hw-prim \
  hw-rankselect \
  hw-rankselect-base \
  hw-simd \
  hw-streams \
  hw-succinct \
  hw-xml \
  hyperloglog \
  identicon \
  incremental-parser \
  influxdb \
  inline-c \
  interpolate \
  interpolator \
  invertible \
  irc-client \
  jose \
  json-rpc \
  katip \
  koofr-client \
  labels \
  lackey \
  language-c-quote \
  language-nix \
  lens-regex \
  linear \
  list-t \
  log-domain \
  lsp-test \
  massiv-io \
  math-functions \
  mcmc-types \
  mergeless \
  metrics \
  mighty-metropolis \
  mixed-types-num \
  mmark \
  monad-par \
  mustache \
  mwc-probability \
  mwc-random \
  netpbm \
  network-ip \
  nsis \
  numeric-extras \
  once \
  opensource \
  pandoc \
  pandoc-citeproc \
  pandoc-csv2table \
  pantry \
  parsers \
  partial-isomorphisms \
  path-extra \
  path-io \
  persistable-record \
  persistable-types-HDBC-pg \
  persistent-pagination \
  persistent-qq \
  persistent-sqlite \
  pipes-extras \
  pipes-random \
  planb-token-introspection \
  plotlyhs \
  postgresql-binary \
  pretty-sop \
  primitive-extras \
  product-isomorphic \
  product-profunctors \
  protocol-radius \
  protocol-radius-test \
  purescript-bridge \
  pushbullet-types \
  qm-interpolated-string \
  qrcode-juicypixels \
  rainbow \
  rainbox \
  random-bytestring \
  rasterific-svg \
  rattle \
  rdf \
  rebase \
  records-sop \
  relational-query \
  relational-query-HDBC \
  relational-record \
  relational-schemas \
  req \
  req-conduit \
  rerebase \
  sampling \
  sbp \
  sequence-formats \
  sequenceTools \
  servant-JuicyPixels \
  servant-auth-server \
  servant-auth-swagger \
  servant-checked-exceptions \
  servant-checked-exceptions-core \
  servant-docs \
  servant-elm \
  servant-foreign \
  servant-js \
  servant-mock \
  servant-purescript \
  servant-rawm \
  servant-server \
  servant-static-th \
  servant-subscriber \
  servant-swagger \
  servant-swagger-ui-core \
  servant-websockets \
  serverless-haskell \
  shake \
  shakespeare \
  shell-conduit \
  simple-log \
  singleton-nats \
  singletons \
  smoothie \
  spatial-math \
  speedy-slice \
  statistics \
  stb-image-redux \
  stm-containers \
  stm-hamt \
  stratosphere \
  streaming-bytestring \
  streamly \
  string-interpolate \
  strive \
  structs \
  stylish-haskell \
  svg-tree \
  swagger2 \
  tasty-lua \
  text-builder \
  text-region \
  th-desugar \
  th-orphans \
  th-printf \
  throwable-exceptions \
  thyme \
  tidal \
  time-parsers \
  traverse-with-class \
  tree-diff \
  trifecta \
  ttc \
  tuple-sop \
  turtle \
  type-level-numbers \
  tzdata \
  uncertain \
  uniplate \
  urlpath \
  verbosity \
  vty \
  wai-app-static \
  wai-websockets \
  webdriver \
  webex-teams-api \
  webex-teams-conduit \
  webex-teams-pipes \
  wreq \
  xls \
  xlsx \
  xlsx-tabular \
  xml-hamlet \
  xml-html-qq \
  yesod \
  yesod-auth \
  yesod-auth-hashdb \
  yesod-core \
  yesod-form \
  yesod-gitrev \
  yesod-newsfeed \
  yesod-persistent \
  yesod-sitemap \
  yesod-static \
  yesod-test \
  yesod-websockets \
  zippers
