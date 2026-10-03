Pod::Spec.new do |spec|
  spec.name = 'inttegro_flutter'
  spec.version = '0.4.0'
  spec.summary = 'Flutter bridge for the native Inttegro payment sheet.'
  spec.homepage = 'https://inttegro.com'
  spec.license = { type: 'MIT' }
  spec.author = { 'Inttegro Eng' => 'engineering@inttegro.com' }
  spec.source = {
    git: 'https://github.com/inttegro/inttegro-sdk-flutter.git',
    tag: spec.version.to_s,
  }
  spec.source_files = 'Classes/**/*.{h,m,mm}'
  spec.ios.deployment_target = '16.0'
  spec.static_framework = true

  spec.dependency 'Flutter'
  spec.dependency 'Inttegro', '0.3.0'
end
