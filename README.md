sandbox
=======

VagrantでChefのcookbookをテストする場合、ある時点の仮想マシンの状態のスナップショットをとっておきいつでも戻せるようにできると便利。
saharaプラグインをインストールすると簡単に実現できる。

https://github.com/jedi4ever/sahara

sahara - `vagrant sandbox`

```
vagrant plugin install sahara
vagrant sandbox on
vagrant sandbox commit
vagrant sandbox rollback
vagrant sandbox off
```

hello
========

execute
---------

最も直感的な`execute`リソース
http://docs.opscode.com/resource_execute.html

```
execute 'hello' do
  command 'echo hello >> /tmp/hello.txt'
end
```

ちょっとわざとらしいですがこれだとhello.txtの中身が増え続けていきます

```
execute 'hello' do
  command 'echo hello >> /tmp/hello.txt'
  not_if { File.exists?('/tmp/hello.txt') }
end
```

executeを使う時には条件の指定が妥当かを気をつけましょう。

### 補足

ガードについて
http://docs.opscode.com/resource_common.html#guards

file
---------

ファイル操作を簡単にしてくれる'file'リソース
http://docs.opscode.com/resource_file.html

```
file '/tmp/hello.txt' do
  action :create
  content 'hello'
end
```

このように自分で冪等性を確保するよりも組み込みのリソースをうまく使うことでレシピが簡潔になり、作者の意図も明確になるため可能な部分は`execute`を使わないで実装していくと良さそうです。

### 補足

#### 属性について

`action`: このリソースがどのような動作をするのか。`create`の他に`delete`ももちろんあります

このようにリソースは、"どのような種類のリソースなのか"と"そのリソースはどのような属性を持つのか"という要素によって実際の動作が決定されます。

#### name属性について

> The path to the file. Default value: the name of the resource block (see Syntax section above).

多くの場合にリソース名は特別な意味を持ちます。どのような意味を持つかはリソースによって異なるためリファレンスを参照しましょう。

実習
--------------

777でvagrant.vagrantのファイルを作ってみよう

editor
========

Chefは実行時にrootになって動いている点に注意が必要。

```
cookbook_file "#{ENV['HOME']}/.vimrc" do
  action :create
  source '.vimrc'
end
```

上記だとrootのホームディレクトリに.vimrcが作られる。

特定ユーザのホームディレクトリに設定を作りたければ次のように絶対パスを指定すると共にuserとgroupを明示する必要がある。

```
cookbook_file '/home/vagrant/.vimrc' do
  action :create
  source '.vimrc'
  user 'vagrant'
  group 'vagrant'
end
```

あらかじめ内容が決まっているファイルをサーバ上に配置したい場合は`cookbook_file`リソースが便利
http://docs.opscode.com/resource_cookbook_file.html

実習
------------

`Vim`で`NeoBundle`を使えるようにしてみよう
https://github.com/Shougo/neobundle.vim

nginx
======

nginxのインストールと設定は、chefのレシピの書き方について伝えるサンプルでよく出てきます。
ただし、CentOSはデフォルトではnginxがリポジトリに入っていないので若干面倒です。

Berkshelf - サードパーティーCookbook
---------------------------------

CentOSではnginxはepelリポジトリに入っているので、yumにリポジトリを追加する必要があります。
自分でリポジトリを追加するレシピを書いても良いのですが、ここではBerkshelfを使ってサードパーティークックブックをインストールして使ってみます。

chef-repo/Berksfile

```
site :opscode

cookbook 'yum-epel'
```

[yum-epelクックブック](http://community.opscode.com/cookbooks/yum-epel)

サードパーティークックブックには二種類あります

type | 説明    | 参考
-------|-------|----
LWRP(lightweight resource and provider) | 新しい種類のリソースを作れるようになる  | http://opsrock.in/2013/09/10/735
LWRP以外 | 普通に自分が書いたクックブックと同様に属性を指定して実行する | 

yum-epelはLWRPではないので普通に`run_list`に追加して使います

```
{
    "run_list":[
        "recipe[hello]",
        "recipe[editor]",
        "recipe[yum-epel]"
    ]
}
```

実行するとyumのリポジトリにEPELが加わります。

レシピの分割
----------

これまで書いてきた`recipe[nginx]`は`nginx/recipes/default.rb`を暗黙的に指しており、明示的に`recipe[nginx::default]`と書くことも可能です。
このことはつまり、`nginx/recipes/package.rb`を作成して`recipe[nginx::package]`と指定することが可能だということを意味しています。

レシピの依存関係
-------------

http://docs.opscode.com/essentials_cookbook_recipes.html#assign-dependencies

サンプルのnginxレシピは、`yum-epel`クックブックに依存しています。そこで、`nginx/metadata.rb`に依存関係を記述することができます。

```
depends 'yum-epel'
```

ただし、これは単なる宣言であって自動的に`yum-epel`が実行されるといった機能は持ちません。

レシピの中から他の特定のレシピを呼び出して実行するには、`include_recipe`関数を使います。
本サンプルでは、`nginx::default`を呼び出した時に自動的に`nginx`クックブックの他のレシピを呼び出す目的で使用しています。

```
include_recipe 'nginx::package'
include_recipe 'nginx::config'
```

ただし、これは若干無理やりな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめてしまえば良いでしょう。

レシピの属性
---------------

`nginx/attributes/config.rb`には、`nginx::config`レシピで使用する属性のデフォルト値が記述されています。

```
default['nginx']['port'] = 80
```

この属性は、`node`、`role`や`environment`など`chef-repo`の様々な場所で指定することができ、その優先順位は[厳密に決まっています](http://docs.opscode.com/essentials_cookbook_attribute_files.html#attribute-precedence)。

`default`はデフォルト属性を格納するhashですが、クックブックの適用時には、様々な場所で指定された属性とあわせて`node`hashに格納されます。
そのため、レシピの中で参照する時には`node`hashを使用します。

この値は、普通に`nginx/recipes/*.rb`といったレシピの中だけでなく、`nginx/templates/default/*.erb`といったテンプレートの中でも使用できます。

```
  listen       <%= node['nginx']['port'] %> default_server;

```

テンプレート
---------------

多くの場合において、サーバを設定する時には固定値の設定ファイルを配置するだけでなくサーバの種類や条件などによって異なった設定値を持った設定ファイルを配置したくなるものです。
chefにビルトインされたtemplateリソースを使うことでこのような目的を簡単に実現することができます。

http://docs.opscode.com/essentials_cookbook_templates.html

templateリソースは、cookbook_fileリソースと似ていますが、ファイルを配置するのは`templates`ディレクトリの中です。
このファイルはtemplateリソースに記述された属性に従い[ERB(Embedded Ruby)](http://ja.wikipedia.org/wiki/ERuby)で値を埋め込むことができます。
埋め込む値はtemplateリソースの属性に指定することもできますし、`node`hashの値を埋め込むこともできます。

```
  listen       <%= node['nginx']['port'] %> default_server;

```

通知
---------------

http://docs.opscode.com/resource_common.html#notifications

nginxは、設定ファイルを書き換えた時に設定ファイルを再読み込みする必要があります。
このように○○した時に☓☓するといった目的に使用するのが通知(notifications)です。

例えば、次のコードは、templateリソースが適用された場合に`nginx`という名前の`serviceリソース`に対して`:reload`アクションを実行するように通知を送ります。

```
template 'default.conf' do
  action :create
  path '/etc/nginx/conf.d/default.conf'
  source 'default.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :reload,'service[nginx]'
end
```

templateリソースは、レシピ適用時にテンプレートを穴埋めした文字列と書き換え対象ファイルの内容が一致する場合には何もしないので、設定を変更した場合にのみnginxが設定を再読み込みすることになります。

補足
================

### subscribe

`notifies`と逆に指定したリソースが適用された場合にのみ自分自身を適用する`subscribe`という仕組みもあります

### :delayedと:immediately

デフォルトでは、通知内容をキューに入れて全レシピを適用し終わった後に通知先リソースを適用する`:delayed	`オプションが適用されています。すぐに実行したい場合は`:immediately`オプションを使用します。

### action :nothing

例えば、`service[nginx]`リソースが次のように記述されている場合、templateリソースの適用状態にかかわらず、`service[nginx]`リソースは`:start`アクションを実行してしまいます。

```
service 'nginx' do
  action :start
end
```

通知を受けた場合にのみ適用させたいリソースには、`:nothing`アクションを指定しておくことでこの問題を回避できます。

```
service 'nginx' do
  action :nothing
end
```

`action`に何も指定しない場合には、`start`や`create`などそのリソースで指定されているデフォルトのアクションが暗黙的に指定されることに注意が必要です。
