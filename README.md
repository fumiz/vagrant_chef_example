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

`nginx/attributes/config.rb`には、`nginx::config`レシピで使用する属性のデフォルトåは、`yum-epel`クックブックに依ånginx']['port'] = 80
```

この属性は、`node`、`role`や`environment`など`chef-repo`の様々な場所で指定することができ、その優先順位は[厳密に決まっています](http://docs.opscode.com/essentials_cookbook_attribute_³出す目的で使用しています。

```
include_recipe 'nginx::package'
include_recipe 'nginx::config'
```

ただし、これは若干無理やりな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめてしまえば良いでしょう。

レシピの属性
----------ぁ、これは若干無理やりな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめã¬シピで使用する属性のデフォルトåは、`yum-epel`クックブックに依ånginx']['port'] = 80
```

この属性は、`node`、`role`や`environment`など`chef-repo`の様々な場所で指定することができ、その倓の属性は、`node`、`role`や`environment`など`chef-repo`の様々な場所で指定することができ、そのæe.com/essentials_cookbook_attribute_³出す目的で使用しています。

```
include_recipe 'nginx::package'
include_recipe 'nginx::config'
```

ただし、これは若干無琨ã¦います。

```
include_recipe 'nginx::package'
includokりな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめてしまえば良いでしょã¨て`default.rb`にまとめてしまえば良いでしょ¤ã

レシピの属性
----------ぁ、これは若干無RB§のデフォルトåは、`yum-epel`クックブックに依ånginx']['port'] = 80
```

この属性は、`node`、`role`や`environment`など`chef-repo`の様々な場所で指宀¾ånginx']['port'] = 80
```

この属性は、`node`、`r
 e`や`environment`など`chef-repo`の様々な場所で指å`

通知
---------------

http://docs.opscode.com/resource_common.html#notifications

nginxは、設定ファイルを書き換えた時に設定ファイルを再読み込みする必要があります。
このように○○した時に☓☓するといった目的に使用するのが通知(notifications)で'nginx::package'
includokりな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめてしªã¾えば良いでしょã¨て`default.rb`にまとめてしまえば良いでしょ¤ã

レシピの属性
--------' まえば良いでしょ¤ã

レシピの属性
-------
 m-epel`クックブックに依ånginx']['port'] = 80
```

この属性は、`node`、`role`や`environment`など`chefteepo`の様々な場所で指å`

通知
---------------

http://docs.opscode.com/resource_common.html#notifications

nginxは、設定ファイルを書き換えた時に設定ファイルを再読み込みする必要があります。
このã://docs.opscode.com/resource_common.html#notifications

nginub¯、設定ファイルを書き換えた時に設定ファãルを再読み込みする必要があります。
このãに○○した時に☓☓するといった目的に使用
ãな使い方で、これくらいの分量と内容なら全て`default.rb`にまとめてしªã¾えば良いでしょã¨て`default.rb`にまとめてしまえば良いでしょ¤ã

レシピの属性
--------' まえば良いでしょゆ。

レシピの属性
--------' まえば良いでしょ〆。

レシピの属性
-------
 m-epel`クックブックて依ånginx']['port'] = 80
```

この属性は、`node`、`le`や`environment`など`chefteepo`の様々な場所で指ã`

通知
---------------

http://docs.opscode.com/resource action :start
end
```

通知を受けた場合にのみ適用させたいリソースには、`:nothing`アクションを指定しておくことでこの問題を回避できます。

```
service 'nginx' do
  action :nothing
end
```

`action`に何も指定しない場合には、`start`や`create`などそのリソースで指定されているデフォルトのアクションが暗黙的に指定されることに注意が必要です。
