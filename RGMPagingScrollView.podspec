Pod::Spec.new do |s|
  s.name         = 'RGMPagingScrollView'
  s.version      = '1.0'
  s.summary      = 'iOS 5 compatible paging UIScrollView subclass'
  s.homepage     = 'https://github.com/rydermackay/RGMPagingScrollView'
  s.license      = 'MIT'  
  s.author =     { 'Ryder Mackey' => 'notsure@email' }
  s.source       = { :git => 'https://github.com/runmad/RGMPagingScrollView.git', :tag => '1.0' }
  s.platform     = :ios, '5.0'
  s.source_files = 'RGMPagingScrollView/*.{h,m}'
  s.requires_arc = true
end
